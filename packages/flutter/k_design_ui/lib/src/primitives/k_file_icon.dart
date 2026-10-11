import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Original VSCode Great Icons assets. The containing row owns the label.
class KFileIcon extends StatelessWidget {
  const KFileIcon({
    required this.name,
    this.folder = false,
    this.expanded = false,
    this.size = 16,
    super.key,
  });
  final String name;
  final bool folder, expanded;
  final double size;
  static const extensions = {
    'md': 'markdown.svg',
    'markdown': 'markdown.svg',
    'txt': 'notepad.svg',
    'ts': 'typescript.svg',
    'tsx': 'typescript.svg',
    'js': 'javascript.svg',
    'jsx': 'javascript.svg',
    'json': 'json.svg',
    'svg': 'svg.svg',
    'png': 'image.png',
    'jpg': 'image.png',
    'jpeg': 'image.png',
    'gif': 'image.png',
    'webp': 'image.png',
    'mp4': 'video.png',
    'webm': 'video.png',
    'mov': 'video.png',
    'mp3': 'audio.png',
    'wav': 'audio.png',
    'ogg': 'audio.png',
    'pdf': 'pdf.svg',
    'zip': 'zip.svg',
    'doc': 'word.svg',
    'docx': 'word.svg',
    'xls': 'excel.svg',
    'xlsx': 'excel.svg',
    'html': 'html.svg',
    'htm': 'html.svg',
    'css': 'css.svg',
  };
  @override
  Widget build(BuildContext context) {
    final extension = name.contains('.')
        ? name.split('.').last.toLowerCase()
        : '';
    final file = folder
        ? '_fd_default${expanded ? '-open' : ''}.svg'
        : extensions.containsKey(extension)
        ? '_f_${extensions[extension]}'
        : '_file.png';
    final path = 'assets/great-icons/$file';
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: file.endsWith('.svg')
            ? SvgPicture.asset(
                path,
                package: 'k_design_ui',
                width: size,
                height: size,
              )
            : Image.asset(
                path,
                package: 'k_design_ui',
                width: size,
                height: size,
                fit: BoxFit.contain,
              ),
      ),
    );
  }
}
