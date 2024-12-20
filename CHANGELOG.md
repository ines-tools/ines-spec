# Changelog
All structural changes to ines-spec are documented here. Changes to the example data set are not documented. Changes/additions to parameter descriptions are not documented unless there is a change in the unit of measure.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)

## [Unreleased]

## [1.0.0]

### *Important*

Moving to version based branches - main branch is ditched. The reason is to make it clear that certain version of ines-spec is in use. Moving to new major version likely means considerable amount of code updates to scripts that read/write ines-spec. There can also be changes within branch, but they should be limited to additions (that shouldn't break anything) or to very minor changes that should have minimal consequences for downstream code.

### Added

- First draft of ines-output-spec
- Stochastic parameters for most parameters with time series
- set: co2_max_cumulative, co2_max_period, co2_price, same for NOx and SO2
- unit__to_node and node__to_unit: so2_emission_rate
- unit: min_uptime, min_downtime, online_cost
- node: commodity_limit, commodity_price_ladder
- node: storage_state_binding_method with options 
- node: storage_state_fix_method with options
- node: storage_loss_absolute, storage_loss_from_storage_capacity, storage_loss_from_stored_energy
- node: storage_cost_of_stored_energy
- node__link__node: Added ramp_limits and ramp_cost and ramp_method
- link: operational_cost can also be time_series
- solve_pattern: stochastic_scope, stochastic_forecasts_in_use (experimenta, time_resolution_scope, time_resolution
- set: co2_price can be also time_series
- New reserve parameters: 
    * unit__node__reserve: offline_reserve_provision_share, forward_reserve_to_reserve
    * set_reserve: update_frequency, gate_closure, reserve_reactivation_time, reserve_requirement_forecast
- unit, node, link: investment_uses_integer, investment_co2_emissions, fixed_co2_emissions

### Changed

- node: storage_lifetime can only be constant (array of periods used to be also possible, but that makes things too complicated in the results side. From now on, use separate storages if functionality needed.)
- link: lifetime can only be constant (array of periods used to be also possible, but that makes things too complicated in the results side. From now on, use separate links if functionality needed.)
- unit: lifetime can only be constant (array of periods used to be also possible, but that makes things too complicated in the results side. From now on, use separate units if functionality needed.)
- link and node__link__node: added array of periods and time series for efficiency parameter.
- node: commodity_price_ladder changed from array to 1d-map
- set: temporality renamed to time_resolution
- reserve: activation_time and duration moved to set__reserve entity_class

## Removed

- temporality class (moved time_resolution to solve_pattern and set)

git commit -m "v1.0.0 updates including investment CO2, integer investments, reserve parameters"
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
