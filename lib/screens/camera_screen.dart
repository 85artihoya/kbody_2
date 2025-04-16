class CameraScreen extends StatefulWidget {
  final String viewType;
  
  const CameraScreen({
    super.key,
    required this.viewType,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

// ... existing code ... 