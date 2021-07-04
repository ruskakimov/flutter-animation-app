import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:provider/provider.dart';
import 'package:mooltik/editing/data/exporter_model.dart';

class ExportDialog extends StatelessWidget {
  const ExportDialog({
    Key? key,
    this.sideWidth = 280,
    this.loadingStrokeWidth = 20,
  })  : assert(
          sideWidth >= 280,
          'Minimum flutter dialog width is 280px.',
        ),
        assert(loadingStrokeWidth < sideWidth / 2),
        super(key: key);

  final double sideWidth;
  final double loadingStrokeWidth;

  @override
  Widget build(BuildContext context) {
    final exporter = context.watch<ExporterModel>();

    return PortalEntry(
      visible: exporter.isExporting,
      portal: AbsorbPointer(),
      child: Dialog(
        shape: CircleBorder(),
        child: SizedBox(
          width: sideWidth,
          height: sideWidth,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: _LoadingIndicator(
                  value: exporter.progress,
                  strokeWidth: loadingStrokeWidth,
                ),
              ),
              if (exporter.isInitial)
                _ExportButton(
                  diameter: sideWidth - loadingStrokeWidth * 2,
                  onTap: exporter.start,
                ),
              if (exporter.isDone)
                TextButton(
                  onPressed: exporter.openOutputFile,
                  child: _LargeText('Open'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator({
    Key? key,
    required this.value,
    required this.strokeWidth,
  }) : super(key: key);

  final double value;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Prevent stroke from overflowing widget, as stroke is centered around the widget's edge.
      padding: EdgeInsets.all(strokeWidth / 2),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CircularProgressIndicator(
              value: value,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
              backgroundColor: Colors.black12,
              strokeWidth: strokeWidth,
            ),
          ),
          _LargeText(value < 1 ? _formatProgress(value) : ''),
        ],
      ),
    );
  }

  String _formatProgress(double value) =>
      '${(value * 100).toStringAsFixed(0)}%';
}

class _LargeText extends StatelessWidget {
  const _LargeText(this.text, {Key? key}) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    Key? key,
    required this.diameter,
    this.onTap,
  }) : super(key: key);

  final double diameter;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      color: Theme.of(context).colorScheme.primary,
      highlightColor: Colors.white12,
      splashColor: Colors.white,
      shape: CircleBorder(),
      onPressed: onTap,
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: Center(
          child: Text(
            'Export video',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.9,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}