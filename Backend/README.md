## Backend Components

### Firebase Backend
- **Cloud Functions**:
  - Receive image/video inputs from the app.
  - Communicate with the Gemini model for initial descriptions or hazard detection for videos.
  - Communicate with the locally hosted Multimodal LLM for scene-to-text conversion and hazard detection for images.

- **Firebase Storage**:
  - Stores videos temporarily for processing by the Gemini model.

### Communication Between Components

- **App <-> Firebase Backend**:
  - The app captures and uploads images/videos to Firebase Storage.
  - Firebase Cloud Functions process the uploaded media, making requests to the Gemini model for initial descriptions or hazard detection for videos and to the locally hosted Multimodal LLM for images.
  - Results are sent back to the app for display and interaction with the user.

