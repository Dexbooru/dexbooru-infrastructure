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

var IMAGE_MIMETYPES = "image/jpeg,image/png,image/jpg,image/webp"

var logger = log.New(os.Stdout, "post-image-anime-series-classifier:", log.LstdFlags)

var wg sync.WaitGroup

func handler(_ context.Context, sqsEvent events.SQSEvent) error {
	ctx := context.Background()

	webhookSecret, found := os.LookupEnv("WEBHOOK_SECRET")
	if !found {
		logger.Fatalln("Could not find a webhook secret properly set, with the following name: WEBHOOK_SECRET")
	}

	webhookUrl, found := os.LookupEnv("WEBHOOK_URL")
	if !found {
		logger.Fatalln("Could not find a webhook url properly set, with the following name: WEBHOOK_URL")
	}

	cdnDomainName, found := os.LookupEnv("CDN_DOMAIN_NAME")
	if !found {
		logger.Fatalln("Could not find a CDN domain name properly set, with the following name: CDN_DOMAIN_NAME")
	}

	geminiApiKey, found := os.LookupEnv("GEMINI_API_KEY")
	if !found {
		logger.Fatalln("Could not find a gemini api key properly set, with the following name: GEMINI_API_KEY")
	}

	geminiClient, err := genai.NewClient(ctx, &genai.ClientConfig{
		APIKey:  geminiApiKey,
		Backend: genai.BackendGeminiAPI,
	})
	if err != nil {
		logger.Fatal("Could not initialize the Gemini client successfully!")
	}

	requestClient := &http.Client{
		Transport: &http.Transport{
			MaxIdleConns:    MAX_IDLE_CONNECTIONS,
			IdleConnTimeout: IDLE_CONNECTION_TIMEOUT,
		},
	}

	postImageRecords := parseRecords(sqsEvent.Records)
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
		}
	}

	if len(classificationResults) == 0 {
		logger.Println("No classification results for current event batch from the queue")
		return nil
	}

	uploadedResults := uploadClassificationResults(classificationResults, requestClient, webhookUrl, webhookSecret)
	if !uploadedResults {
		logger.Println("Failed to upload classification results")
		return errors.New("Failed to upload classification results")
	}

	logger.Printf("%d classification results uploaded and sent to the webhook url: %s\n", len(classificationResults), webhookUrl)

	return nil
}

func main() {
	lambda.Start(handler)
}
