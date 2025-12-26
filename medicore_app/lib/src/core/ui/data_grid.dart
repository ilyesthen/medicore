import 'package:flutter/material.dart';
import '../theme/medicore_colors.dart';
import '../theme/medicore_typography.dart';
import '../theme/medicore_dimensions.dart';

/// Cockpit Data Grid - Dense spreadsheet-like table
/// Features: Visible grid lines, zebra striping, compact rows
class DataGrid extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;
  final void Function(int)? onRowTap;
  final void Function(int)? onRowDoubleTap;
  final Widget? Function(int rowIndex, int columnIndex, String value)? customCellBuilder;
  final int? selectedRowIndex;
  
  const DataGrid({
    super.key,
    required this.headers,
    required this.rows,
    this.onRowTap,
    this.onRowDoubleTap,
    this.customCellBuilder,
    this.selectedRowIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: MediCoreColors.gridLines,
          width: MediCoreDimensions.gridLineWidth,
        ),
      ),
      child: Column(
        children: [
          // Header Row
          Container(
            height: MediCoreDimensions.gridHeaderHeight,
            decoration: const BoxDecoration(
              color: MediCoreColors.deepNavy,
              border: Border(
                bottom: BorderSide(
                  color: MediCoreColors.gridLines,
                  width: MediCoreDimensions.gridLineWidth,
                ),
              ),
            ),
            child: Row(
              children: headers.map((header) {
                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MediCoreDimensions.spacingM,
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      header.toUpperCase(),
                      style: MediCoreTypography.gridHeader.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Data Rows with optimized virtual scrolling
          Expanded(
            child: ListView.builder(
              itemCount: rows.length,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: true,
              cacheExtent: 100,
              itemBuilder: (context, rowIndex) {
                final row = rows[rowIndex];
                final isEven = rowIndex % 2 == 0;
                final isSelected = selectedRowIndex == rowIndex;
                
                return GestureDetector(
                  onTap: onRowTap != null ? () => onRowTap!(rowIndex) : null,
                  onDoubleTap: onRowDoubleTap != null ? () => onRowDoubleTap!(rowIndex) : null,
                  child: Container(
                    height: MediCoreDimensions.gridRowHeight,
                    decoration: BoxDecoration(
                      // VERY obvious selection using brand kit Professional Blue
                      color: isSelected
                          ? MediCoreColors.professionalBlue.withOpacity(0.35) // Professional Blue with high visibility
                          : isEven 
                              ? MediCoreColors.paperWhite 
                              : MediCoreColors.zebraRowAlt,
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected 
                              ? MediCoreColors.professionalBlue // Professional Blue border for selected
                              : MediCoreColors.gridLines,
                          width: isSelected ? 2.5 : MediCoreDimensions.gridLineWidth,
                        ),
                        top: isSelected
                            ? BorderSide(
                                color: MediCoreColors.professionalBlue,
                                width: 2.5,
                              )
                            : BorderSide.none,
                        left: isSelected
                            ? BorderSide(
                                color: MediCoreColors.professionalBlue,
                                width: 5,
                              )
                            : BorderSide.none,
                        right: isSelected
                            ? BorderSide(
                                color: MediCoreColors.professionalBlue,
                                width: 2.5,
                              )
                            : BorderSide.none,
                      ),
                    ),
                    child: Row(
                      children: List.generate(row.length, (columnIndex) {
                        final cell = row[columnIndex];
                        final customWidget = customCellBuilder?.call(rowIndex, columnIndex, cell);
                        
                        return Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: MediCoreDimensions.spacingM,
                            ),
                            alignment: Alignment.centerLeft,
                            child: customWidget ?? Text(
                              cell,
                              style: MediCoreTypography.dataCell,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
