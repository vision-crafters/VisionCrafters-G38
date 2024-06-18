## Backend Components

### Firebase Backend
- **Cloud Functions**:
  - Receive image/video inputs from the app.
  - Communicate with the Gemini model for initial descriptions or hazard detection for videos.
  - Communicate with the locally hosted Multimodal LLM for scene-to-text conversion and hazard detection for images.

