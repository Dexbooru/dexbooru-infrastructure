package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"

	"github.com/aws/aws-lambda-go/events"
	"github.com/h2non/bimg"
)

const RESIZED_IMAGE_WIDTH_PX = 450
const RESIZED_IMAGE_HEIGHT_PX = 450
const IMAGE_MIMETYPES = "image/jpeg,image/png,image/jpg,image/webp"

func parseRecordsToPostImages(records []events.SQSMessage) []PostImageRecord {
	postImageRecords := make([]PostImageRecord, 0, len(records))

	for _, message := range records {
		messageBytes := []byte(message.Body)
		var postImageRecord PostImageRecord

		err := json.Unmarshal(messageBytes, &postImageRecord)
		if err != nil {
			logger.Printf("Failed to parse message into a post image record with the following content: %s\n", message.Body)
			continue
		}

		// Set the MessageId from SQS for tracking
		postImageRecord.MessageId = message.MessageId
		postImageRecords = append(postImageRecords, postImageRecord)
	}

	return postImageRecords
}

func downloadImage(client *http.Client, postImageRecord PostImageRecord, targetDomain string) (ImageClassificationInput, error) {
	targetUrl, err := url.Parse(postImageRecord.ImageUrl)
	if err != nil {
		return ImageClassificationInput{}, err
	}

	if targetUrl.Hostname() != targetDomain {
		return ImageClassificationInput{}, fmt.Errorf("Invalid domain: %s, while expecting %s", targetUrl.Hostname(), targetDomain)
	}

	response, err := http.Get(postImageRecord.ImageUrl)
	if err != nil {
		return ImageClassificationInput{}, err
	}

	defer response.Body.Close()

	contentBytes, err := io.ReadAll(response.Body)
	if err != nil {
		return ImageClassificationInput{}, err
	}

	mimeType := strings.ToLower(http.DetectContentType(contentBytes))
	if !strings.Contains(IMAGE_MIMETYPES, mimeType) {
		return ImageClassificationInput{}, fmt.Errorf("Invalid mimetype: %s, while expecting an image for the url %s", mimeType, postImageRecord.ImageUrl)
	}

	image := bimg.NewImage(contentBytes)
	resizedImage, err := image.Resize(RESIZED_IMAGE_WIDTH_PX, RESIZED_IMAGE_HEIGHT_PX)
	if err != nil {
		return ImageClassificationInput{}, err
	}

	return ImageClassificationInput{
		PostId:    postImageRecord.PostId,
		ImageUrl:  postImageRecord.ImageUrl,
		Bytes:     resizedImage,
		Mimetype:  mimeType,
		MessageId: postImageRecord.MessageId,
	}, nil
}

func uploadClassificationResults(results []ImageClassificationOutput, client *http.Client, webhookUrl string, webhookSecret string) (*ImageClassificationWebhookApiResponse, error) {
	requestHeaders := http.Header{
		"Content-Type":      {"application/json"},
		"X-WEBHOOK-API-KEY": {webhookSecret},
	}
	requestBody := struct {
		Results []ImageClassificationOutput `json:"results"`
	}{
		Results: results,
	}

	requestBodyBytes, err := json.Marshal(requestBody)
	if err != nil {
		return nil, err
	}

	request, err := http.NewRequest(http.MethodPost, webhookUrl, bytes.NewReader(requestBodyBytes))
	if err != nil {
		return nil, err
	}
	request.Header = requestHeaders

	response, err := client.Do(request)
	if err != nil {
		return nil, err
	}

	if response.StatusCode != http.StatusCreated {
		return nil, fmt.Errorf("something went wrong in the webhook call from Dexbooru")
	}

	defer response.Body.Close()

	var webHookResponse ImageClassificationWebhookApiResponse
	responseBodyBytes, err := io.ReadAll(response.Body)
	if err != nil {
		return nil, err
	}

	err = json.Unmarshal(responseBodyBytes, &webHookResponse)
	if err != nil {
		return nil, err
	}

	return &webHookResponse, nil
}
