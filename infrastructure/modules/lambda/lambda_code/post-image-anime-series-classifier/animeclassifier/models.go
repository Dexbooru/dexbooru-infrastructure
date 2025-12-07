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
	MessageId string
}

type ImageClassificationInput struct {
	PostId    string
	ImageUrl  string
	Bytes     []byte
	Mimetype  string
	MessageId string
}

type ImageClassificationOutput struct {
	PostId        string `json:"postId"`
	SourceTitle   string `json:"sourceTitle"`
	SourceType    string `json:"sourceType"`
	CharacterName string `json:"characterName"`
	MessageId     string `json:"-"`
}

type ImageClassificationWebhookApiResponse struct {
	RecordsAdded  int      `json:"recordsAdded"`
	PostIdsServed []string `json:"postIdsServed"`
}
