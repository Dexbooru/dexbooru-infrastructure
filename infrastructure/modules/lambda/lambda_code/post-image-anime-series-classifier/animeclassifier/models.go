package main

type PostImageRecord struct {
	PostId   string `json:"postId"`
	ImageUrl string `json:"imageUrl"`
}

type ImageClassificationInput struct {
	PostId   string
	ImageUrl string
	Bytes    []byte
	Mimetype string
}

type ImageClassificationOutput struct {
	PostId        string `json:"postId"`
	SourceTitle   string `json:"sourceTitle"`
	SourceType    string `json:"sourceType"`
	CharacterName string `json:"characterName"`
}
