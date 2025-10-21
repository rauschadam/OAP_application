import 'package:airport_test/api_services/api_classes/valid_reservation.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReservationList extends StatefulWidget {
  final List<ValidReservation> reservations;
  final String? listTitle;
  final Map<String, String> columns; // pl. {'Rendszám': 'licensePlate'}
  final Map<String, String Function(ValidReservation)>? formatters;
  final double? maxHeight;
  final double? maxWidth;
  final Function(ValidReservation)? onRowTap;
  final ValidReservation? selectedReservation;
  final String? emptyText;

  const ReservationList({
    super.key,
    required this.reservations,
    this.listTitle,
    required this.columns,
    this.formatters,
    this.maxHeight,
    this.maxWidth,
    this.onRowTap,
    this.selectedReservation,
    this.emptyText,
  });

  @override
  State<ReservationList> createState() => _ReservationListState();
}

class _ReservationListState extends State<ReservationList> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.medium),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(AppBorderRadius.small)),
      ),
      constraints: BoxConstraints(
        maxHeight: widget.maxHeight ?? double.infinity,
        maxWidth: widget.maxWidth ?? double.infinity,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.listTitle != null)
            Padding(
              padding: const EdgeInsets.only(left: AppPadding.small),
              child: Text(
                widget.listTitle!,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          const SizedBox(height: AppPadding.medium),
          widget.reservations.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(AppBorderRadius.small),
                  width: double.infinity,
                  child: Text(widget.emptyText ?? 'Nincsenek foglalások'),
                )
              : Flexible(
                  child: Column(
                    children: [
                      _buildColumnTitles(widget.columns),
                      _buildRows(widget.reservations),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildColumnTitles(Map<String, String> columns) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppPadding.small,
        horizontal: AppPadding.medium,
      ),
      decoration: BoxDecoration(
        color: Colors.blue.shade300,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppBorderRadius.small),
          topRight: Radius.circular(AppBorderRadius.small),
        ),
      ),
      child: Row(
        children: [
          for (var columnTitle in columns.keys)
            Expanded(
              child: Text(
                columnTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRows(List<ValidReservation> reservations) {
    final double? actualMaxHeight = widget.maxHeight;

    return Flexible(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: actualMaxHeight ?? double.infinity,
        ),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: reservations.length,
          itemBuilder: (context, index) {
            final reservation = reservations[index];
            return Column(
              children: [
                InkWell(
                  onTap: widget.onRowTap != null
                      ? () => widget.onRowTap!(reservation)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppPadding.small,
                      horizontal: AppPadding.medium,
                    ),
                    decoration: BoxDecoration(
                      color: _getRowColor(reservation, index),
                      borderRadius: index == reservations.length - 1
                          ? const BorderRadius.only(
                              bottomLeft:
                                  Radius.circular(AppBorderRadius.small),
                              bottomRight:
                                  Radius.circular(AppBorderRadius.small),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        for (var fieldName in widget.columns.values)
                          Expanded(
                            child: _buildCell(reservation, fieldName),
                          ),
                      ],
                    ),
                  ),
                ),
                if (index < reservations.length - 1)
                  const Divider(height: 1, thickness: 1),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCell(ValidReservation reservation, String fieldName) {
    // Ha van egyedi formázó
    if (widget.formatters != null &&
        widget.formatters!.containsKey(fieldName)) {
      return Text(widget.formatters![fieldName]!(reservation));
    }

    dynamic value;

    // Típusbiztos mezőelérés switch-csel:
    switch (fieldName) {
      case 'webParkingId':
        value = reservation.webParkingId;
        break;
      case 'partnerId':
        value = reservation.partnerId;
        break;
      case 'Name':
        value = reservation.partner_Sortname;
        break;
      case 'LicensePlate':
        value = reservation.licensePlate;
        break;
      case 'articleNameHUN':
        value = reservation.articleNameHUN;
        break;
      case 'state':
        value = reservation.state;
        break;
      case 'arriveDate':
        value = DateFormat('yyyy.MM.dd HH:mm').format(reservation.arriveDate);
        break;
      case 'leaveDate':
        value = DateFormat('yyyy.MM.dd HH:mm').format(reservation.leaveDate);
        break;
      case 'email':
        value = reservation.email;
        break;
      case 'phone':
        value = reservation.phone;
        break;
      case 'description':
        value = reservation.description;
        break;
      default:
        value = 'Vmi más';
    }

    return Text(value?.toString() ?? '-');
  }

  Color _getRowColor(ValidReservation reservation, int index) {
    if (widget.selectedReservation != null &&
        reservation.webParkingId == widget.selectedReservation?.webParkingId) {
      return Colors.grey.shade300;
    }
    return index.isEven ? Colors.grey.shade50 : Colors.white;
  }
}
