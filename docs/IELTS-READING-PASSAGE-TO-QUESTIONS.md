# IELTS Reading — Passage → Questions (Cursor)

**Best workflow:** you supply an original passage; Cursor only writes questions/answers/explanations as JSON; TechRen imports into MongoDB (Manage Exams → Import reading).

Scoring stays local. Do not ask Cursor to save to MongoDB — import via the app/API.

---

## Copy everything below into a new Cursor chat

````text
You are an IELTS Reading Exam Generator.

I will provide a reading passage.

Your task is to transform it into a complete IELTS Academic Reading section.

DO NOT rewrite the passage.
DO NOT shorten or paraphrase the passage.
Copy the passage text into the JSON "passage" field EXACTLY as given.

Only generate the exam metadata and questions.

Generate:
1. Passage title (short, academic)
2. estimatedBand (number, e.g. 6.5)
3. wordCount (integer)
4. difficulty: Easy | Medium | Hard
5. readingTimeMinutes (integer)
6. Exactly 13 IELTS-style questions using a MIXTURE of types.

Use ONLY these type strings in JSON (exact spelling):
- MULTIPLE_CHOICE
- TRUE_FALSE_NOT_GIVEN
- MATCHING_HEADINGS
- MATCHING_INFORMATION
- SENTENCE_COMPLETION
- SUMMARY_COMPLETION
- SHORT_ANSWER

Do NOT use only one type. Use at least 3 different types.

Each question must contain:
- number (1–13)
- type
- question
- options (array; required for MULTIPLE_CHOICE, MATCHING_*, and use ["True","False","Not Given"] for TRUE_FALSE_NOT_GIVEN)
- answer (string; the single correct answer)
- explanation (1–2 sentences citing the idea in the passage)

Return ONLY valid JSON. No markdown. No comments.

JSON format:
{
  "title": "",
  "difficulty": "Medium",
  "estimatedBand": 6.5,
  "readingTimeMinutes": 8,
  "wordCount": 0,
  "module": "Academic",
  "passage": "",
  "questions": []
}

========== READING PASSAGE (do not rewrite) ==========

The Rise of Urban Farming

Over the past two decades, cities around the world have experienced rapid population growth. As urban areas expand, the demand for fresh food has increased significantly while the amount of available agricultural land has steadily decreased. This challenge has encouraged governments, businesses, and individuals to explore new methods of food production that can operate successfully within densely populated environments. One of the most promising solutions is urban farming.

Urban farming refers to the cultivation of crops and the raising of small livestock within or around cities. Unlike traditional farming, which often requires large areas of land, urban farms make use of rooftops, balconies, unused warehouses, community gardens, and even vertical structures. These innovative approaches allow food to be produced close to consumers, reducing transportation costs and minimizing environmental impact.

One popular method is vertical farming. In this system, plants are grown in stacked layers inside specially designed buildings. Artificial lighting and carefully controlled temperatures allow crops to grow throughout the year regardless of weather conditions. Some vertical farms also use hydroponic systems, where plants receive nutrients through water rather than soil. This technique reduces water consumption and eliminates many soil-borne diseases.

Another growing trend is community gardening. Residents work together to transform unused land into productive gardens where vegetables, herbs, and fruits can be cultivated. Besides supplying fresh produce, these gardens strengthen community relationships, provide educational opportunities for children, and encourage healthier lifestyles.

Urban farming also offers environmental benefits. Local food production reduces the distance that products travel before reaching consumers, decreasing greenhouse gas emissions associated with transportation. Green roofs covered with vegetation help lower building temperatures, improve air quality, and reduce rainwater runoff during storms.

Despite its advantages, urban farming faces several challenges. Land in cities is expensive, making it difficult to expand farming operations. In addition, some urban soils contain pollutants that may affect crop safety. Farmers must carefully test soil quality or use alternative growing systems such as raised beds or hydroponics. Energy costs for indoor farms can also be high because artificial lighting and climate control require significant electricity.

Technological innovation continues to improve the efficiency of urban agriculture. Smart sensors monitor soil moisture, nutrient levels, and temperature in real time. Artificial intelligence can analyze plant health and predict disease before visible symptoms appear. Automated irrigation systems ensure that plants receive exactly the amount of water they need, reducing waste.

Experts believe urban farming will not replace traditional agriculture but will become an important supplement to global food production. As cities continue to grow and environmental concerns become increasingly urgent, combining conventional farming with modern urban agriculture may help create a more sustainable food system for future generations.

========== END PASSAGE ==========
````

---

## After Cursor returns JSON

1. Copy the JSON object only.
2. In TechRen: subject → **IELTS → Manage Exams → Import reading**.
3. Paste JSON → Import. Opens as an unpublished reading draft (1 passage, ~13 questions).
4. Repeat with 2 more original passages for a full 3-passage / ~40-question mock (or merge later).

---

## Student reading text (same passage)

Students see this as the passage body after import — keep it as-is in the `"passage"` field.
