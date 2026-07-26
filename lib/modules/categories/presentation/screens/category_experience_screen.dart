import 'package:client/common/domain/services/service_category_config.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/modules/categories/application/category_experience_controller.dart';
import 'package:client/modules/categories/data/category_experience_repository.dart';
import 'package:client/modules/categories/domain/category_experience.dart';
import 'package:client/modules/categories/domain/service_booking_entry.dart';
import 'package:client/modules/categories/presentation/widgets/category_empty_state.dart';
import 'package:client/modules/categories/presentation/widgets/category_error_state.dart';
import 'package:client/modules/categories/presentation/widgets/category_hero.dart';
import 'package:client/modules/categories/presentation/widgets/category_quick_actions.dart';
import 'package:client/modules/categories/presentation/widgets/category_reveal_overlay.dart';
import 'package:client/modules/categories/presentation/widgets/category_service_card.dart';
import 'package:client/modules/categories/presentation/widgets/category_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CategoryExperienceScreen extends StatefulWidget {
  final ServiceCategoryId categoryId;

  const CategoryExperienceScreen({
    super.key,
    required this.categoryId,
  });

  @override
  State<CategoryExperienceScreen> createState() =>
      _CategoryExperienceScreenState();
}

class _CategoryExperienceScreenState extends State<CategoryExperienceScreen> {
  late final CategoryExperienceController _controller;
  late final CategoryPresentationConfig _config;

  @override
  void initState() {
    super.initState();
    _config = CategoryPresentationRegistry.forId(widget.categoryId);
    _controller = CategoryExperienceController(
      dpLocator<CategoryExperienceRepository>(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    if (_controller.status == CategoryExperienceStatus.idle) {
      _controller.load(
        categoryId: widget.categoryId,
        config: _config,
        reducedMotion: reducedMotion,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onOptionTapped(ServiceOptionSummary option) {
    final flowType = ServiceBookingEntryResolver.resolve(widget.categoryId);
    final extra = ServiceBookingEntryResolver.extraFor(
      flowType: flowType,
      option: option,
      config: _config,
    );
    final routeName =
        ServiceBookingEntryResolver.routeNameForCategory(widget.categoryId);
    context.pushNamed(routeName, extra: extra);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return Stack(
            children: [
              _buildContent(context),
              if (_controller.showOverlay)
                Positioned.fill(
                  child: CategoryRevealOverlay(
                    config: _config,
                    decision: _controller.revealDecision,
                    onDismiss: _controller.dismissOverlay,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return CustomScrollView(
      slivers: [
        CategoryHeroSliver(
          config: _config,
          onBack: () => context.pop(),
        ),
        CategoryQuickActionsSliver(
          chips: _config.filterChips,
          selectedLabel: _controller.selectedChipLabel,
          accentColor: _config.theme.primaryAccent,
          onChipSelected: _controller.selectChip,
        ),
        ..._buildBody(context),
      ],
    );
  }

  List<Widget> _buildBody(BuildContext context) {
    return switch (_controller.status) {
      CategoryExperienceStatus.idle ||
      CategoryExperienceStatus.loading =>
        [const CategorySkeletonList()],
      CategoryExperienceStatus.failure => [
          SliverToBoxAdapter(
            child: CategoryErrorState(
              message: _controller.error,
              accentColor: _config.theme.primaryAccent,
              onRetry: () => _controller.retry(
                categoryId: widget.categoryId,
                config: _config,
                reducedMotion: MediaQuery.of(context).disableAnimations,
              ),
            ),
          ),
        ],
      CategoryExperienceStatus.success => _buildOptionsList(context),
    };
  }

  List<Widget> _buildOptionsList(BuildContext context) {
    final options = _controller.visibleOptions;
    if (options.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: CategoryEmptyState(
            accentColor: _config.theme.primaryAccent,
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        sliver: SliverToBoxAdapter(
          child: Text(
            '${options.length} service${options.length == 1 ? '' : 's'} available',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withOpacity(0.6),
                ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CategoryServiceCard(
                option: options[i],
                accentColor: _config.theme.primaryAccent,
                onTap: () => _onOptionTapped(options[i]),
              ),
            ),
            childCount: options.length,
          ),
        ),
      ),
      if (_config.processSteps.isNotEmpty)
        SliverToBoxAdapter(
          child: _HowItWorks(
            steps: _config.processSteps,
            accent: _config.theme.primaryAccent,
          ),
        ),
      const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
    ];
  }
}

// ── "How it works" section ─────────────────────────────────────────────────

class _HowItWorks extends StatelessWidget {
  final List<CategoryProcessStep> steps;
  final Color accent;

  const _HowItWorks({required this.steps, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How it works',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          ...steps.map((step) => _StepTile(step: step, accent: accent)),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final CategoryProcessStep step;
  final Color accent;

  const _StepTile({required this.step, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step.ordinal.toString(),
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
