List<Map<String, dynamic>> getChatHistory(List<Map<String, dynamic>> messages) {
  List<Map<String, dynamic>> formattedMessages = [];
  int count = 0;
  for (int i = messages.length - 1; i >= 0; i--) {
    Map<String, dynamic> message = messages[i];

    // Check if the message contains an image
    bool isMedia = message['type'] == 'media';

    // If we found an image within the latest 10 messages, stop collecting messages
    if (isMedia && count > 0) {
      formattedMessages.add({
        "role": 'user',
        "content": 'Please describe the image/video.',
      });
      break;
    }

    // Add the message to the formatted list
    formattedMessages.add({
      "role": message['role'],
      "content": message['content'],
    });

    // Increment the count of messages retrieved
    count++;

    // Stop collecting messages after retrieving the latest 10
    if (count >= 10) {
      break;
    }
  }

  return formattedMessages.reversed.toList();
}
