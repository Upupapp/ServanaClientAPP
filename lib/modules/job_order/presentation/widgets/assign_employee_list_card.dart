import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/modules/job_order/presentation/widgets/employee_list_card.dart';

class AssignEmployeeListCard extends StatefulWidget {
  const AssignEmployeeListCard({
    super.key,
    this.onToggle,
    this.value = false,
    required this.name,
    required this.phone,
    required this.photoURL,
  });
  final String name;
  final String phone;
  final String photoURL;
  final bool value;
  final void Function(bool value)? onToggle;

  @override
  State<AssignEmployeeListCard> createState() => _AssignEmployeeListCardState();
}

class _AssignEmployeeListCardState extends State<AssignEmployeeListCard> {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(
          width: 25,
        ),
        Expanded(
          child: EmployeeListCard(
            name: widget.name,
            contactNo: widget.phone,
            photoUrl: widget.photoURL,
          ),
        ),
        InkWell(
          onTap: () {
            widget.onToggle?.call(!widget.value);
          },
          child: Theme(
            data: Theme.of(context).copyWith(
              unselectedWidgetColor: ColorPalette.secondaryAccentColor,
            ),
            child: Transform.scale(
              scale: 1.3,
              child: Checkbox(
                value: widget.value,
                checkColor: ColorPalette.primaryText,
                activeColor: ColorPalette.primaryColor,
                shape: const CircleBorder(),
                onChanged: (value) {
                  widget.onToggle?.call(!widget.value);
                },
              ),
            ),
          ),
        ),
        const Gap(20),
      ],
    );
  }
}
