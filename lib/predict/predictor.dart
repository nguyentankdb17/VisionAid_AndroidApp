import 'package:ultralytics_yolo/ultralytics_yolo_platform_interface.dart';
import 'package:ultralytics_yolo/yolo_model.dart';

/// Abstract class for all predictors.
abstract class Predictor {
  /// Constructor to create an instance of [Predictor].
  Predictor(this.model);

  /// The model used for prediction.
  final YoloModel model;

  /// The platform instance used to run inference.
  final ultralyticsYoloPlatform = UltralyticsYoloPlatform.instance;

  /// Loads the model.
  Future<String?> loadModel({bool useGpu = false}) =>
      ultralyticsYoloPlatform.loadModel(model.toJson(), useGpu: useGpu);
}
