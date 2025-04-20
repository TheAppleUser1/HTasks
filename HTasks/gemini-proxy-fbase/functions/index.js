const functions = require("firebase-functions");
const axios = require("axios");

exports.geminiProxy = functions.https.onRequest(async (req, res) => {
  const apiKey = functions.config().gemini.key;

  try {
    const response = await axios.post(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent",
      {
        contents: [
          {
            parts: [
              {
                text: req.body.prompt || "Hello from Firebase!",
              },
            ],
          },
        ],
      },
      {
        headers: {
          "Content-Type": "application/json",
          "x-goog-api-key": apiKey,
        },
      }
    );

    res.status(200).send(response.data);
  } catch (err) {
    console.error("Gemini proxy error:", err);
    res.status(500).send("Something went wrong");
  }
});
