// AIModel class ek downloaded/available AI model
// ki information ko represent karegi.
class AIModel {
  // Model ki unique ID.
  // Example: "gemma-3-4b"
  final String id;

  // User ko dikhne wala model name.
  // Example: "Gemma 3 4B"
  final String name;

  // Model ka version.
  // Example: "1.0"
  final String version;

  // Model file ka format.
  // Example: "GGUF"
  final String format;

  // Model ki quantization.
  // Example: "Q4_K_M"
  final String quantization;

  // Model ka size bytes mein.
  final int size;

  // Jahan se model download hoga.
  final String downloadUrl;

  // UI mein model ke size aur use-case ko readable form mein dikhate hain.
  final String sizeLabel;
  final String category;

  // Constructor.
  // Jab AIModel object banega to ye information deni hogi.
  AIModel({
    required this.id,
    required this.name,
    required this.version,
    required this.format,
    required this.quantization,
    required this.size,
    required this.downloadUrl,
    required this.sizeLabel,
    required this.category,
  });
}
