package main

type SQSBatchResponse struct {
	BatchItemFailures []SQSBatchItemFailure `json:"batchItemFailures"`
}

type SQSBatchItemFailure struct {
	ItemIdentifier string `json:"itemIdentifier"`
}

type PostImageRecord struct {
	PostId    string `json:"postId"`
	ImageUrl  string `json:"imageUrl"`
	MessageId string // SQS Message ID for tracking failures
}

type ImageClassificationInput struct {
	PostId    string
	ImageUrl  string
	Bytes     []byte
	Mimetype  string
	MessageId string // SQS Message ID for tracking
}

type ImageClassificationOutput struct {
	PostId        string `json:"postId"`
	SourceTitle   string `json:"sourceTitle"`
	SourceType    string `json:"sourceType"`
	CharacterName string `json:"characterName"`
	MessageId     string `json:"-"` // Track but don't serialize to webhook
}
