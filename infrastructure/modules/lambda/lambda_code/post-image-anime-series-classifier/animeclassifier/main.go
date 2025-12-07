package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"os"
	"sync"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"google.golang.org/genai"
)

const MAX_IDLE_CONNECTIONS = 10
const IDLE_CONNECTION_TIMEOUT = 25 * time.Second

var logger = log.New(os.Stdout, "post-image-anime-series-classifier:", log.LstdFlags)

var wg sync.WaitGroup

func buildBatchResponse(failedMessageIds map[string]bool) SQSBatchResponse {
	batchItemFailures := make([]SQSBatchItemFailure, 0, len(failedMessageIds))
	for messageId := range failedMessageIds {
		batchItemFailures = append(batchItemFailures, SQSBatchItemFailure{
			ItemIdentifier: messageId,
		})
	}
	return SQSBatchResponse{
		BatchItemFailures: batchItemFailures,
	}
}

func handler(_ context.Context, sqsEvent events.SQSEvent) (SQSBatchResponse, error) {
	ctx := context.Background()

	failedMessageIds := make(map[string]bool)
	for _, record := range sqsEvent.Records {
		failedMessageIds[record.MessageId] = true
	}

	lambdaEnvironment, found := os.LookupEnv("ENVIRONMENT")
	if !found {
		lambdaEnvironment = "local"
	}

	webhookSecret, found := os.LookupEnv("WEBHOOK_SECRET")
	if !found {
		return SQSBatchResponse{}, errors.New("Could not find a webhook secret properly set, with the following name: WEBHOOK_SECRET")
	}

	webhookUrl, found := os.LookupEnv("WEBHOOK_URL")
	if !found {
		return SQSBatchResponse{}, errors.New("Could not find a webhook url properly set, with the following name: WEBHOOK_URL")
	}

	cdnDomainName, found := os.LookupEnv("CDN_DOMAIN_NAME")
	if !found {
		return SQSBatchResponse{}, errors.New("Could not find a CDN domain name properly set, with the following name: CDN_DOMAIN_NAME")
	}

	geminiApiKey, found := os.LookupEnv("GEMINI_API_KEY")
	if !found {
		return SQSBatchResponse{}, errors.New("Could not find a gemini api key properly set, with the following name: GEMINI_API_KEY")
	}

	geminiClient, err := genai.NewClient(ctx, &genai.ClientConfig{
		APIKey:  geminiApiKey,
		Backend: genai.BackendGeminiAPI,
	})
	if err != nil {
		return SQSBatchResponse{}, errors.New("Could not initialize the Gemini client successfully!")
	}

	requestClient := &http.Client{
		Transport: &http.Transport{
			MaxIdleConns:    MAX_IDLE_CONNECTIONS,
			IdleConnTimeout: IDLE_CONNECTION_TIMEOUT,
		},
	}

	postImageRecords := parseRecordsToPostImages(sqsEvent.Records)
	imageInputCh := make(chan ImageClassificationInput, len(postImageRecords))

	for _, postImageRecord := range postImageRecords {
		wg.Add(1)

		go func(postImageRecord PostImageRecord) {
			defer wg.Done()

			imageInput, err := downloadImage(requestClient, postImageRecord, cdnDomainName)
			if err != nil {
				logger.Printf("Error downloading image: %v with the following URL: %s\n", err, postImageRecord.ImageUrl)
				return
			}

			imageInputCh <- imageInput
		}(postImageRecord)
	}

	go func() {
		wg.Wait()
		close(imageInputCh)
	}()

	classificationResults := make([]ImageClassificationOutput, 0)
	for imageInput := range imageInputCh {
		classificationResult, err := classifyImage(ctx, geminiClient, imageInput)
		if err != nil {
			logger.Printf("Error classifying image: %v with the following URL: %s\n", err, imageInput.ImageUrl)
			continue
		}

		if classifiedResult(classificationResult) {
			classificationResults = append(classificationResults, classificationResult)
			delete(failedMessageIds, imageInput.MessageId)
		} else {
			logger.Printf("Image did not meet classification criteria for URL: %s\n", imageInput.ImageUrl)
		}
	}

	if len(classificationResults) == 0 {
		logger.Println("No classification results for current event batch from the queue")
		return buildBatchResponse(failedMessageIds), nil
	}

	if lambdaEnvironment == "production" {
		uploadedResults, err := uploadClassificationResults(classificationResults, requestClient, webhookUrl, webhookSecret)
		if err != nil {
			logger.Printf("Failed to upload classification results with error: %v\n", err)

			for _, result := range classificationResults {
				failedMessageIds[result.MessageId] = true
			}
			return buildBatchResponse(failedMessageIds), errors.New("Failed to upload classification results")
		}

		logger.Printf("Uploaded %d records, serving post ids: %v\n", uploadedResults.RecordsAdded, uploadedResults.PostIdsServed)
		logger.Printf("%d classification results uploaded and sent to the webhook url: %s\n", len(classificationResults), webhookUrl)
	}

	return buildBatchResponse(failedMessageIds), nil
}

func main() {
	lambda.Start(handler)
}
