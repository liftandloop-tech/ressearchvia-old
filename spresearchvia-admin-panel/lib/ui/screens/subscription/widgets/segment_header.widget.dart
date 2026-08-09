import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'segment_header_cell.widget.dart';

class SegmentHeader extends TableRow {
  SegmentHeader()
    : super(
        decoration: BoxDecoration(color: AppTheme.gray50),
        children: [
          const SegmentHeaderCell('Segment Name'),
          const SegmentHeaderCell('Category'),
          const SegmentHeaderCell('Status'),
          const SegmentHeaderCell('Created On'),
          const SegmentHeaderCell('Actions'),
        ],
      );
}
