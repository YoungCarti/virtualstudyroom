import os
from typing import Any
from firebase_functions import firestore_fn, options
from firebase_admin import initialize_app, firestore
from google import genai
from google.genai import types
from dotenv import load_dotenv

# Initialize Firebase Admin
initialize_app()

# Load environment variables
load_dotenv()

# Configure Gemini API
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if GEMINI_API_KEY:
    client = genai.Client(api_key=GEMINI_API_KEY)


@firestore_fn.on_document_created(
    document="classes/{classCode}/groups/{groupId}/messages/{messageId}",
    region="asia-southeast1",  # Match your Firestore location
)
def on_message_created(
    event: firestore_fn.Event[firestore_fn.DocumentSnapshot | None],
) -> None:
    """
    Triggered when a new message is created in any group chat.
    If the message mentions @gemini, generate an AI response.
    """
    if event.data is None:
        return

    # Get message data
    message_data = event.data.to_dict()
    if not message_data:
        return

    message_text = message_data.get("text", "")
    sender_id = message_data.get("senderId", "")

    # Check if message mentions @gemini and is not from AI itself
    if "@gemini" not in message_text.lower() or sender_id == "gemini_ai":
        return

    # Extract the question (remove @gemini mention)
    question = message_text.replace("@gemini", "").replace("@Gemini", "").strip()

    if not question:
        question = "Hello! How can I help you?"

    try:
        # Generate AI response using Gemini
        response_text = generate_gemini_response(question)

        # Get document path info
        class_code = event.params["classCode"]
        group_id = event.params["groupId"]

        # Store AI response as a new message
        db = firestore.client()
        db.collection("classes").document(class_code).collection(
            "groups"
        ).document(group_id).collection("messages").add(
            {
                "text": response_text,
                "senderId": "gemini_ai",
                "createdAt": firestore.SERVER_TIMESTAMP,
                "isAIMessage": True,
                "aiModel": "gemini-pro",
                "replyToMessageId": event.params["messageId"],
                "deletedBy": [],
            }
        )

    except Exception as e:
        print(f"Error generating AI response: {str(e)}")
        # Optionally, send an error message
        try:
            db = firestore.client()
            class_code = event.params["classCode"]
            group_id = event.params["groupId"]

            db.collection("classes").document(class_code).collection(
                "groups"
            ).document(group_id).collection("messages").add(
                {
                    "text": "Sorry, I encountered an error processing your request. Please try again later.",
                    "senderId": "gemini_ai",
                    "createdAt": firestore.SERVER_TIMESTAMP,
                    "isAIMessage": True,
                    "aiModel": "gemini-pro",
                    "deletedBy": [],
                }
            )
        except:
            pass


def generate_gemini_response(prompt: str) -> str:
    """
    Generate a response using Google's Gemini AI.

    Args:
        prompt: The user's question or prompt

    Returns:
        The AI-generated response text
    """
    if not GEMINI_API_KEY:
        return "Gemini API key is not configured. Please set GEMINI_API_KEY in environment variables."

    try:
        # Add context to make the AI more helpful for study groups
        enhanced_prompt = f"""You are Gemini AI, an intelligent assistant helping students in their study group chat. 
Be helpful, friendly, and concise in your responses. If the question is academic, provide clear explanations.

User question: {prompt}"""

        # Use the new genai Client API
        response = client.models.generate_content(
            model='gemini-2.0-flash-exp',
            contents=enhanced_prompt,
        )

        return response.text

    except Exception as e:
        print(f"Error calling Gemini API: {str(e)}")
        return f"I apologize, but I encountered an error: {str(e)}"
