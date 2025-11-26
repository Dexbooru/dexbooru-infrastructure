package main

import (
	"context"
	"encoding/json"
	"fmt"
	"math/rand/v2"

	"google.golang.org/genai"
)

const GEMINI_SYSTEM_INSTRUCTION = `You are a source and character classifier, for pop-culture related media from Japan.
Given an image, classify it into an source title, source type (VIDEOGAME, ANIME, MANGA, OTHER) and character name.

The format is a JSON object in the following shape:
{sourceTitle: string, sourceType: string, characterName: string}.
If you are unsure, respond with {sourceTitle: 'Unknown', sourceType: 'Unknown', characterName: 'Unknown'}.`
const GEMINI_MODEL_NAME = "gemini-2.0-flash"
const GEMINI_MODEL_TEMPERATURE_MIN = 0.0
const GEMINI_MODEL_TEMPERATURE_MAX = 0.2
const GEMINI_RESPONSE_TYPE = "application/json"

func buildModelPromptInstructions(imageInput ImageClassificationInput) ([]*genai.Content, *genai.GenerateContentConfig) {
	modelTemperature := GEMINI_MODEL_TEMPERATURE_MIN + rand.Float32()*(GEMINI_MODEL_TEMPERATURE_MAX-GEMINI_MODEL_TEMPERATURE_MIN)
	parts := []*genai.Part{
		genai.NewPartFromBytes(imageInput.Bytes, imageInput.Mimetype),
		genai.NewPartFromText("Perform classification on the image in the appropriate response format"),
	}
	contents := []*genai.Content{
		genai.NewContentFromParts(parts, genai.RoleUser),
	}
	config := &genai.GenerateContentConfig{
		Temperature:       &modelTemperature,
		ResponseMIMEType:  GEMINI_RESPONSE_TYPE,
		SystemInstruction: genai.NewContentFromText(GEMINI_SYSTEM_INSTRUCTION, genai.RoleModel),
	}

	return contents, config
}

func classifyImage(ctx context.Context, geminiClient *genai.Client, imageInput ImageClassificationInput) (ImageClassificationOutput, error) {
	if len(imageInput.Bytes) == 0 {
		return ImageClassificationOutput{}, fmt.Errorf("Could not classify image, as the image is empty")
	}

	promptContents, promptConfig := buildModelPromptInstructions(imageInput)
	classificationResponse, err := geminiClient.Models.GenerateContent(ctx, GEMINI_MODEL_NAME, promptContents, promptConfig)
	if err != nil {
		return ImageClassificationOutput{}, err
	}

	resultText := classificationResponse.Text()
	var classificationOutput ImageClassificationOutput
	if err := json.Unmarshal([]byte(resultText), &classificationOutput); err != nil {
		return ImageClassificationOutput{}, fmt.Errorf("Could not parse classification response: %w", err)
	}
	classificationOutput.PostId = imageInput.PostId

	return classificationOutput, nil
}

func classifiedResult(result ImageClassificationOutput) bool {
	return result.SourceTitle != "Unknown" && result.SourceType != "Unknown" && result.CharacterName != "Unknown"
}
