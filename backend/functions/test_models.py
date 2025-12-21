import os
import google.generativeai as genai
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configure Gemini API
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)
    
    print("Testing available Gemini models...")
    print("-" * 50)
    
    # Try different model names
    models_to_test = [
        "gemini-pro",
        "gemini-1.5-pro",
        "gemini-1.0-pro",
        "models/gemini-pro",
    ]
    
    for model_name in models_to_test:
        try:
            print(f"\nTrying model: {model_name}")
            model = genai.GenerativeModel(model_name)
            response = model.generate_content("Say 'Hello'")
            print(f"✅ SUCCESS: {model_name}")
            print(f"Response: {response.text[:50]}")
            break
        except Exception as e:
            print(f"❌ FAILED: {model_name}")
            print(f"Error: {str(e)[:100]}")
else:
    print("GEMINI_API_KEY not found in .env file")
