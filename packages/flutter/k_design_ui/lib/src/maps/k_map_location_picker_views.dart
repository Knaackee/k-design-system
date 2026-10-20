part of 'k_map_location_picker.dart';

extension _KMapLocationPickerViews on _KMapLocationPickerState {
  Widget _buildChoice(KDesignTokens tokens, KMapLocation? location) => Padding(
    key: const ValueKey('k-map-location-choice'),
    padding: EdgeInsets.all(tokens.spaceCardPadding + tokens.spaceControlGap),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: tokens.spaceControlGap,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child:
              widget.leading ??
              DecoratedBox(
                decoration: BoxDecoration(
                  color: tokens.colorBrandPrimaryBackground,
                  borderRadius: BorderRadius.circular(tokens.radiusCard),
                ),
                child: Padding(
                  padding: EdgeInsets.all(tokens.spaceCardPadding),
                  child: KIcon(
                    KIconName.mapPin,
                    size: 28,
                    color: tokens.colorBrandPrimaryForeground,
                  ),
                ),
              ),
        ),
        KText(widget.labels.title, variant: KTextVariant.heading2),
        KText(
          widget.labels.description,
          style: TextStyle(
            color: tokens.colorTextMuted,
            fontSize: tokens.fontHeading5Size,
            height: tokens.spaceHairline * 1.5,
          ),
        ),
        KButton(
          label: widget.labels.search,
          onPressed: _openSearch,
          fullWidth: true,
          leading: const KIcon(KIconName.search),
        ),
        if (widget.onLocate != null)
          KButton(
            label: widget.labels.locate,
            onPressed: _locate,
            loading: _operationBusy,
            fullWidth: true,
            variant: KButtonVariant.secondary,
            leading: const KIcon(KIconName.locateFixed),
          ),
        if (location != null)
          KButton(
            label: widget.labels.back,
            onPressed: _closePanel,
            variant: KButtonVariant.ghost,
          ),
        if (_error) _errorText(tokens),
      ],
    ),
  );

  Widget _buildSearch(KDesignTokens tokens) => ConstrainedBox(
    key: const ValueKey('k-map-location-search'),
    constraints: BoxConstraints(maxHeight: tokens.spaceHairline * 560),
    child: Padding(
      padding: EdgeInsets.all(tokens.spaceCardPadding + tokens.spaceControlGap),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: tokens.spaceControlGap,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: KButton(
              label: widget.labels.back,
              onPressed: _showChoice,
              variant: KButtonVariant.ghost,
              leading: const KIcon(KIconName.arrowLeft),
            ),
          ),
          KText(widget.labels.search, variant: KTextVariant.heading2),
          KSearchField(
            key: const ValueKey('k-map-location-search-input'),
            controller: _searchController,
            focusNode: _searchFocus,
            label: widget.labels.search,
            placeholder: widget.labels.placeholder,
            clearable: true,
            onChanged: _queueSearch,
          ),
          Flexible(child: _buildResults(tokens)),
          if (_error) _errorText(tokens),
        ],
      ),
    ),
  );

  Widget _buildResults(KDesignTokens tokens) {
    final query = _searchController.text.trim();
    if (_searchBusy) {
      return Semantics(
        liveRegion: true,
        child: Row(
          spacing: tokens.spaceControlGap,
          children: [
            SizedBox(
              width: tokens.componentButtonLoadingIndicatorSize,
              height: tokens.componentButtonLoadingIndicatorSize,
              child: CircularProgressIndicator(
                strokeWidth: tokens.componentButtonLoadingIndicatorStrokeWidth,
                color: tokens.colorTextMuted,
              ),
            ),
            Flexible(
              child: KText(
                widget.labels.searching,
                style: TextStyle(color: tokens.colorTextMuted),
              ),
            ),
          ],
        ),
      );
    }
    if (!_error && query.length >= 2 && _results.isEmpty) {
      return KText(
        widget.labels.empty,
        style: TextStyle(color: tokens.colorTextMuted),
      );
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: tokens.spaceControlGap,
        children: [for (final result in _results) _result(tokens, result)],
      ),
    );
  }

  Widget _result(KDesignTokens tokens, KMapLocation result) => Semantics(
    button: true,
    liveRegion: true,
    label: [result.label, if (result.detail != null) result.detail!].join(', '),
    child: KSurface(
      tone: KSurfaceTone.canvas,
      border: KSurfaceBorder.none,
      radius: KSurfaceRadius.medium,
      child: InkWell(
        onTap: () => _choose(result),
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceControlInsetInline,
            vertical: tokens.spaceControlGap,
          ),
          child: Row(
            spacing: tokens.spaceControlGap,
            children: [
              const KIcon(KIconName.mapPin),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KText(result.label, variant: KTextVariant.label),
                    if (result.detail != null)
                      KText(
                        result.detail!,
                        variant: KTextVariant.caption,
                        style: TextStyle(color: tokens.colorTextMuted),
                      ),
                  ],
                ),
              ),
              const KIcon(KIconName.arrowUpRight),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildPill(KDesignTokens tokens, KMapLocation location) => Semantics(
    key: const ValueKey('k-map-location-pill'),
    button: true,
    label: '${widget.labels.edit}: ${location.label}',
    child: InkWell(
      focusNode: _pillFocus,
      onTap: _openSearch,
      borderRadius: BorderRadius.circular(tokens.radiusFull),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: math.max(48, tokens.sizeHitTarget),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceControlInsetInline,
            vertical: tokens.spaceControlGap,
          ),
          child: Row(
            spacing: tokens.spaceControlGap,
            children: [
              if (_operationBusy)
                SizedBox(
                  width: tokens.componentButtonLoadingIndicatorSize,
                  height: tokens.componentButtonLoadingIndicatorSize,
                  child: CircularProgressIndicator(
                    strokeWidth:
                        tokens.componentButtonLoadingIndicatorStrokeWidth,
                    color: tokens.colorTextPrimary,
                  ),
                )
              else
                const KIcon(KIconName.mapPin),
              Expanded(
                child: KText(
                  _operationBusy ? widget.labels.searching : location.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const KIcon(KIconName.chevronDown),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildHint(
    KDesignTokens tokens,
    Duration duration,
    KMapLocation location,
  ) => PositionedDirectional(
    start: 20,
    end: 20,
    bottom: tokens.spaceHairline * 28,
    child: PointerInterceptor(
      child: AnimatedSlide(
        duration: duration,
        offset: _showHint ? Offset.zero : const Offset(0, .25),
        child: KSurface(
          border: KSurfaceBorder.none,
          radius: KSurfaceRadius.card,
          elevation: KSurfaceElevation.medium,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spaceControlInsetInline,
              vertical: tokens.spaceControlGap,
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: tokens.spaceCardPadding,
              runSpacing: tokens.spaceControlGap,
              children: [
                if (_error)
                  _errorText(tokens)
                else
                  widget.hint ??
                      KText(widget.labels.hint, align: TextAlign.center),
                if (widget.onConfirm != null)
                  KButton(
                    label: widget.labels.confirm,
                    onPressed: _operationBusy || _error
                        ? null
                        : () => widget.onConfirm!(location),
                    trailing: const KIcon(KIconName.arrowRight),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _errorText(KDesignTokens tokens) => Semantics(
    liveRegion: true,
    child: KText(
      widget.labels.error,
      style: TextStyle(color: tokens.colorStatusErrorForeground),
    ),
  );
}
