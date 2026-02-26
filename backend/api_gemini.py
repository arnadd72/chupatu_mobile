import google.generativeai as genai
from flask import Flask, request, jsonify
import PIL.Image
import json

app = Flask(__name__)

# ⚠️ MASUKKAN API KEY GEMINI BOS DI SINI ⚠️
# Dapatkan dari: aistudio.google.com/app/apikey
genai.configure(api_key="AIzaSyB0qB4DjLtjYZWzPZxoYjgZ2r6dN7BX_3c")

@app.route('/analisa_sepatu', methods=['POST'])
def analisa_sepatu():
    # 1. Terima foto dari Flutter
    if 'image' not in request.files:
        return jsonify({'status': 'error', 'message': 'Tidak ada gambar'}), 400

    file = request.files['image']
    img = PIL.Image.open(file.stream)

    # 2. Panggil Gemini 1.5 Flash (Sangat cepat untuk gambar)
    try:
        model = genai.GenerativeModel('gemini-2.5-flash')

        # Prompt sakti untuk memaksa Gemini menjawab pakai format JSON
        prompt = """
        Anda adalah ahli perawatan sepatu profesional. Analisis foto sepatu ini.
        Berikan jawaban HANYA dalam format JSON persis seperti di bawah ini:
        {
            "merk": "Merk sepatu",
            "jenis": "Nama jenis sepatu",
            "kondisi": "Deskripsi singkat bagian yang kotor.",
            "rekomendasi": ["Layanan1", "Layanan2"],
            "tips": "Berikan tips perawatan dalam maksimal 5 poin pendek saja (langsung ke intinya)."
        }

        ATURAN KHUSUS:
        1. 'rekomendasi' WAJIB hanya mengambil dari daftar ini: Unyellowing, Repair, Waterproof, Deep Clean, Repaint, Fast Clean, Pickup.
        2. 'tips' HARUS sangat singkat. Hindari kata-kata pembuka seperti 'Anda bisa mencoba...' atau 'Sangat disarankan untuk...'. Langsung ke poin utamanya.
        3. HANYA OUTPUT JSON. Jangan ada teks lain.
        """

        response = model.generate_content([prompt, img])
        raw_text = response.text.strip()

        # Bersihkan format jika Gemini menambahkan markdown ```json ... ```
        if raw_text.startswith("```json"):
            raw_text = raw_text[7:-3]
        elif raw_text.startswith("```"):
            raw_text = raw_text[3:-3]

        hasil_json = json.loads(raw_text)

        # 3. Kirim balik hasilnya ke Flutter
        return jsonify({
            'status': 'success',
            'data': hasil_json
        })

    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)})

if __name__ == '__main__':
    # Jalan di semua IP address laptop Bos di port 5000
    app.run(host='0.0.0.0', port=5000, debug=True)