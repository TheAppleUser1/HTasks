const axios = require("axios");

module.exports = async (req, res) => {
  const apiKey = process.env.GEMINI_API_KEY;

  try {
    const response = await axios.post(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent",
      {
        contents: [
          {
            parts: [
              {
                text: req.body.prompt || "Hello from Vercel!",
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

    res.status(200).json(response.data);
  } catch (err) {
    console.error("Gemini proxy error:", err);
    res.status(500).json({ error: "Something went wrong" });
  }
};
