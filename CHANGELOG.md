# Changelog
All structural changes to ines-spec are documented here. Changes to the example data set are not documented. Changes/additions to parameter descriptions are not documented unless there is a change in the unit of measure.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)

## [Unreleased]

## [0.6.0]

### Added

- Set: co2_max_cumulative, co2_max_period, co2_price
- Unit: min_uptime, min_downtime, online_cost
- Node: commodity_limit, commodity_price_ladder
- Node: storage_state_binding_method with options 
- Node: storage_state_fix_method with options
- Node: storage_loss_absolute, storage_loss_from_storage_capacity, storage_loss_from_stored_energy


## [0.5.0]

### Added

- Added and updated investment_methods: cumulative_limits (was limit_total_capacity), period_limits, cumulative_and_period_limits, fix_investments
- Changed investment, retirement and existing parameter names to be more systematic:

||New|Old|
|---|---|---|
|link|links_min_cumulative|cumulative_lower_limit|
|link|links_max_cumulative|cumulative_upper_limit|
|link|links_existing|existing_links|
|link|links_invest_fix_period|investment_fix|
|link|links_invest_min_period|investment_lower_limit|
|link|links_invest_max_period|investment_upper_limit|
|link|links_retire_fix_period|retirement_fix|
|node|storages_existing|existing_storages|
|node|storages_min_cumulative|storage_cumulative_lower_limit|
|node|storages_max_cumulative|storage_cumulative_upper_limit|
|node|storages_invest_fix_period|storage_investment_fix|
|node|storages_invest_min_period|storage_investment_lower_limit|
|node|storages_invest_max_period|storage_investment_upper_limit|
|node|storages_retire_fix_period|storage_retirement_fix|
|set|invest_max_period|invest_max_period|
|set|invest_max_total|invest_max_total|
|set|invest_min_period|invest_min_period|
|set|invest_min_total|invest_min_total|
|set|flow_max_cumulative|max_cumulative_flow|
|set|flow_max_instant|max_instant_flow|
|set|flow_min_cumulative|min_cumulative_flow|
|set|flow_min_instant|min_instant_flow|
|unit|units_min_cumulative|cumulative_lower_limit|
|unit|units_max_cumulative|cumulative_upper_limit|
|unit|units_existing|existing_units|
|unit|units_invest_fix_period|investment_fix|
|unit|units_invest_min_period|investment_lower_limit|
|unit|units_invest_max_period|investment_upper_limit|
|unit|units_retire_fix_period|retirement_fix|
|unit|units_fix_cumulative||
|link|links_fix_cumulative||
|node|storages_fix_cumulative||

### Removed

- 'retire_at_the_end_of_lifetime' method from retirement_methods. It was unclear how it would be different from 'retire_as_scheduled'.

## [0.4.0]

### Added

- years_represented parameter to the period class
- Maximum and minimum investment limits for aggregated flow and storage capacities using sets (set has new parameters: invest_max_period, invest_max_total, invest_min_period, invest_min_total)
- Maximum and minimum limits for the aggregated flows using sets (set has new parameters: max_cumulative_flow, max_instant_flow, min_cumulative_flow, min_instant_flow)
- New class 'set__unit_flow' to replace 'set__node__unit'
- Added inertia_constant for unit flows and inertia_limit for sets of nodes
- Added is_non_synchronous for unit flows and links as well as non_synchronous_share for sets of nodes

### Removed
- Class 'set__node__unit' (replaced by 'set__unit_flow')

## [0.3.0]

### Added 

- unit_flow__unit_flow class with parameters to set constraints between the two nodes
- unit__to_node and node__to_unit are now based on superclass unit_flow

### Changed

- Fixed typos in parameter descriptions (MWh to MW in couple of instances)

## [0.2.0]

### Added 

- node entity_class has a new parameter co2_content
- unit__to_node and node__to_unit classes have a new parameter nox_emission_rate

## [0.1.0]

### Added

- The initial data structure for ines-spec. Sufficient feature set for planning problems using energy transfers and simple energy conversions.
