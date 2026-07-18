import 'package:client/common/constants/color_palette.dart';
import 'package:client/modules/job_order/data/enums/job_order_status.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_bloc.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class DashboardUserCard extends StatelessWidget {
  const DashboardUserCard({
    super.key,
    required this.id,
    required this.address,
    this.onTap,
    this.photoUrl,
    required this.merchantName,
    required this.status,
    required this.serviceName,
    required this.date,
    this.width = 380,
  });

  final String id;
  final String merchantName;
  final String? photoUrl;
  final String address;
  final String serviceName;
  final double width;
  final JobOrderStatus status;
  final DateTime date;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: ColorPalette.secondaryBackground,
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      BlocConsumer<JobOrderBloc, JOState>(
                        builder: (context, state) {
                          switch (status) {
                            case JobOrderStatus.accepted:
                              return Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: ColorPalette.primaryColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "READY",
                                  style: TextStyle(
                                    color: ColorPalette.primaryText,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              );
                            case JobOrderStatus.inTransit:
                              return Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: ColorPalette.primaryColorDark,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "DEPLOYED",
                                  style: TextStyle(
                                    color: ColorPalette.primaryText,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              );
                            case JobOrderStatus.inProgress:
                              return Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: ColorPalette.primaryColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "IN PROGRESS",
                                  style: TextStyle(
                                    color: ColorPalette.primaryText,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              );
                            case JobOrderStatus.completed:
                              return Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: ColorPalette.primaryColorDark,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "COMPLETE",
                                  style: TextStyle(
                                    color: ColorPalette.primaryText,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              );
                            default:
                              return Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: ColorPalette.primaryColor
                                      .withOpacity(.85),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "ACCEPTED",
                                  style: TextStyle(
                                    color: ColorPalette.primaryText,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              );
                          }
                        },
                        listener: (context, state) {},
                      ),
                      const Spacer(),
                      Text(
                        "#$id",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Gap(10),
                  CustomStepper(
                    currentStep: status.value,
                    totalSteps: 5,
                  ),
                  const Gap(10),
                  Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Text(
                            merchantName,
                            maxLines: 1,
                            style: TextStyle(
                              color: ColorPalette.secondaryText,
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    DateFormat("EEE MMM. d, yyyy h:mm aa").format(date),
                    maxLines: 1,
                    style: TextStyle(
                      color: ColorPalette.secondaryText,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomStepper extends StatelessWidget {
  const CustomStepper({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.disabled = false,
  });
  final int currentStep;
  final int totalSteps;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        bool isActive = index < currentStep + 1;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 7,
            decoration: BoxDecoration(
              color: (isActive && !disabled)
                  ? ColorPalette.primaryColor
                  : ColorPalette.secondaryBorder,
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
        );
      }),
    );
  }
}
