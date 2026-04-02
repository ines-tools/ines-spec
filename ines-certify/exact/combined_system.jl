import JuMP
using JuMP:@variable, @objective, @constraint
import HiGHS

# window 1

model = JuMP.Model(HiGHS.Optimizer)

s__t = [t for t in 1:10] #intra
s__a = [a for a in 1:3] #inter
s__r = [r for r in 1:2] #representative
s__s = [:cheap_low,:cheap_high,:expensive_low,:expensive_high] #stochastic import_renewables
s__t_gas = [t for t in 1:2:10]
s__t_in_gas = Dict(t=>[t,t+1] for t in s__t_gas)

dt__gas = 2

ps__factor_price = Dict(
    :cheap_low => 1.0,
    :cheap_high => 1.0,
    :expensive_low => 2.0,
    :expensive_high => 2.0
)
ps__wind = [rand(1)[1] for t in s__t]
ps__factor_wind = Dict(
    :cheap_low => ps__wind,
    :cheap_high => (ps__wind .+ 0.2)/1.2,
    :expensive_low => ps__wind,
    :expensive_high => (ps__wind .+ 0.2)/1.2
)
ps__solar = [(sin(t)+1)/2 for t in s__t]
ps__factor_solar = Dict(
    :cheap_low => ps__solar,
    :cheap_high => (ps__solar .+ 0.2)/1.2,
    :expensive_low => ps__solar,
    :expensive_high => (ps__solar .+ 0.2)/1.2
)

p__weight_economic = Dict( # Dict(r => weight)
    1 => 2,
    2 => 1
)
p__weight_delta__battery = Dict( # Dict(a => Dict(r => weight))
    1 => Dict(
        1 => 1.0,
        2 => 0.0
    ),
    2 => Dict(
        1 => 0.5,
        2 => 0.5
    ),
    3 => Dict(
        1 => 0.0,
        2 => 1.0
    ),
)
p__commodity_price__gas_import = Dict( r => Dict(s=> Dict(t => 10.0*ps__factor_price[s] for t in s__t_gas) for s in s__s) for r in s__r)
p__capacity__gas_import = 1000.0
p__existing_units__gas_import = 1.0

p__commodity_price__electricity_import = Dict( r => Dict(s=> Dict(t => 50.0*ps__factor_price[s] for t in s__t) for s in s__s) for r in s__r)
p__capacity__electricity_import = 10.0
p__existing_units__electricity_import = 1.0

p__flow_profile__gas_demand = Dict(r=>Dict(t => 50.0 for t in s__t_gas) for r in s__r)
p__flow_profile__electricity_demand = Dict(r=>Dict(t => 50.0 for t in s__t) for r in s__r)

p__efficiency__gas_distribution = 1.0
p__capacity__gas_distribution = 1000.0
p__existing_units__gas_distribution = 1.0
p__efficiency__electricity_distribution = 1.0
p__capacity__electricity_distribution = 1000.0
p__existing_units__electricity_distribution = 1.0
p__efficiency__electricity_transport = 1.0
p__capacity__electricity_transport = 1000.0
p__existing_units__electricity_transport = 1.0

p__commodity_price__nuclear_unit = 50.0
p__startup_cost__nuclear_unit = 50.0
p__investment_cost__nuclear_unit = 1000.0
p__existing_units__nuclear_unit = 1.0
p__capacity_min__nuclear_unit = 10.0
p__capacity__nuclear_unit = 20.0
p__mut__nuclear_unit = 2
p__mdt__nuclear_unit = 1

p__efficiency__gas_unit = 0.4
p__investment_cost__gas_unit = 600.0
p__existing_units__gas_unit = 0.0
p__capacity__gas_unit = 10.0

p__flow_profile__wind_unit = Dict(r => Dict(s=> Dict(t => ps__factor_wind[s][t] for t in s__t) for s in s__s) for r in s__r)
p__investment_cost__wind_unit = 200.0
p__existing_units__wind_unit = 0.0
p__capacity__wind_unit = 10.0

p__flow_profile__solar_unit = Dict(r => Dict(s=> Dict(t => ps__factor_solar[s][t] for t in s__t) for s in s__s) for r in s__r)
p__investment_cost__solar_unit = 200.0
p__existing_units__solar_unit = 0.0
p__capacity__solar_unit = 10.0

p__investment_cost__battery = 800.0
p__capacity__battery = 20.0
p__existing_units__battery = 0.0
p__capacity_charge__battery = 100.0
p__capacity_discharge__battery = 100.0
p__efficiency__battery = 0.9
p__efficiency_charge__battery = 0.7
p__efficiency_discharge__battery = 0.7

@variable(model,0<=v__flow__gas_import[s__r,s__s,s__t_gas]<=p__capacity__gas_import*p__existing_units__gas_import)
@variable(model,0<=v__flow__electricity_import[s__r,s__s,s__t]<=p__capacity__electricity_import*p__existing_units__electricity_import)

@variable(model,v__investment__nuclear_unit>=p__existing_units__nuclear_unit)
@variable(model,v__flow__nuclear_unit[s__r,s__s,s__t])
@variable(model,v__on__nuclear_unit[s__r,s__s,s__t],Bin)
@variable(model,v__on_up__nuclear_unit[s__r,s__s,s__t],Bin)
@variable(model,v__on_down__nuclear_unit[s__r,s__s,s__t],Bin)

@variable(model,v__investment__gas_unit>=p__existing_units__gas_unit)
@variable(model,0<=v__flow__gas_unit_in[s__r,s__s,s__t_gas])
@variable(model,0<=v__flow__gas_unit_out[s__r,s__s,s__t])

@variable(model,v__investment__wind_unit>=p__existing_units__wind_unit)
@variable(model,0<=v__flow__wind_unit[s__r,s__s,s__t])
@variable(model,v__investment__solar_unit>=p__existing_units__solar_unit)
@variable(model,0<=v__flow__solar_unit[s__r,s__s,s__t])

@variable(model,v__investment__battery>=p__existing_units__battery)
@variable(model,0<=v__state_intra__battery[s__r,s__s,s__t])
@variable(model,0<=v__state_inter__battery[s__s,s__a])
@variable(model,0<=v__charge__battery[s__r,s__s,s__t])
@variable(model,0<=v__discharge__battery[s__r,s__s,s__t])

@variable(model,v__flow__gas_distribution_in[s__r,s__s,s__t_gas])
@variable(model,0<=v__flow__gas_distribution_out[s__r,s__s,s__t_gas]<=p__capacity__gas_distribution*p__existing_units__gas_distribution)
@variable(model,v__flow__electricity_distribution_in[s__r,s__s,s__t])
@variable(model,0<=v__flow__electricity_distribution_out[s__r,s__s,s__t]<=p__capacity__electricity_distribution*p__existing_units__electricity_distribution)
@variable(model,v__flow__electricity_transport_in[s__r,s__s,s__t])
@variable(model,0<=v__flow__electricity_transport_out[s__r,s__s,s__t]<=p__capacity__electricity_transport*p__existing_units__electricity_transport)

@objective(model,Min,sum(p__weight_economic[r]*sum(sum(p__commodity_price__gas_import[r][s][t]*v__flow__gas_import[r,s,t] for t in s__t_gas)+sum(p__commodity_price__electricity_import[r][s][t]*v__flow__electricity_import[r,s,t] + p__startup_cost__nuclear_unit*v__on_up__nuclear_unit[r,s,t]+p__commodity_price__nuclear_unit*v__flow__nuclear_unit[r,s,t] for t in s__t) for s in s__s) for r in s__r) + p__investment_cost__nuclear_unit*(v__investment__nuclear_unit-p__existing_units__nuclear_unit) + p__investment_cost__gas_unit*(v__investment__gas_unit-p__existing_units__gas_unit) + p__investment_cost__solar_unit*(v__investment__solar_unit-p__existing_units__solar_unit) + p__investment_cost__wind_unit*(v__investment__wind_unit-p__existing_units__wind_unit) + p__investment_cost__battery*(v__investment__battery-p__existing_units__battery))

@constraint(model,c__balance__gas_demand[r in s__r, s in s__s, t in s__t_gas],p__flow_profile__gas_demand[r][t] == v__flow__gas_distribution_out[r,s,t])
@constraint(model,c__balance__gas_hub[r in s__r, s in s__s, t in s__t_gas],v__flow__gas_import[r,s,t] == v__flow__gas_distribution_in[r,s,t]+v__flow__gas_unit_in[r,s,t])
@constraint(model,c__balance__electricity_demand[r in s__r, s in s__s, t in s__t],p__flow_profile__electricity_demand[r][t] == v__flow__electricity_distribution_out[r,s,t]+v__flow__solar_unit[r,s,t])
@constraint(model,c__balance__electricity_hub[r in s__r, s in s__s, t in s__t],v__flow__electricity_distribution_out[r,s,t]+v__charge__battery[r,s,t] == v__flow__electricity_transport_out[r,s,t] + v__flow__gas_unit_out[r,s,t] + v__flow__nuclear_unit[r,s,t]+p__efficiency_discharge__battery*v__discharge__battery[r,s,t])
@constraint(model,c__balance__remote_electricity_hub[r in s__r, s in s__s, t in s__t],v__flow__electricity_transport_in[r,s,t] == v__flow__electricity_import[r,s,t] + v__flow__wind_unit[r,s,t])

@constraint(model,c__efficiency__gas_distribution[r in s__r, s in s__s, t in s__t_gas], v__flow__gas_distribution_out[r,s,t]==p__efficiency__gas_distribution*v__flow__gas_distribution_in[r,s,t])
@constraint(model,c__efficiency__electricity_distribution[r in s__r, s in s__s, t in s__t], v__flow__electricity_distribution_out[r,s,t]==p__efficiency__electricity_distribution*v__flow__electricity_distribution_in[r,s,t])
@constraint(model,c__efficiency__electricity_transport[r in s__r, s in s__s, t in s__t], v__flow__electricity_transport_out[r,s,t]==p__efficiency__electricity_transport*v__flow__electricity_transport_in[r,s,t])

@constraint(model,c__efficiency__gas_unit[r in s__r, s in s__s, t in s__t_gas],sum(v__flow__gas_unit_out[r,s,t_in_gas] for t_in_gas in s__t_in_gas[t])==dt__gas*p__efficiency__gas_unit*v__flow__gas_unit_in[r,s,t])
@constraint(model,c__capacity__gas_unit_in[r in s__r, s in s__s, t in s__t_gas],v__flow__gas_unit_in[r,s,t] <= (p__capacity__gas_unit/p__efficiency__gas_unit)*v__investment__gas_unit)
@constraint(model,c__capacity__gas_unit_out[r in s__r, s in s__s, t in s__t],v__flow__gas_unit_out[r,s,t] <= p__capacity__gas_unit*v__investment__gas_unit)

@constraint(model,c__on__nuclear_unit[r in s__r, s in s__s, t in s__t[2:end]],v__on__nuclear_unit[r,s,t]==v__on__nuclear_unit[r,s,t-1]+v__on_up__nuclear_unit[r,s,t]-v__on_down__nuclear_unit[r,s,t])
@constraint(model,c__on_up__nuclear_unit[r in s__r, s in s__s, t in s__t[p__mdt__nuclear_unit:end]],v__on_up__nuclear_unit[r,s,t]<=1-v__on__nuclear_unit[r,s,t]-sum(v__on_down__nuclear_unit[r,s,t-tk] for tk in 1:p__mdt__nuclear_unit-1))
@constraint(model,c__on_down__nuclear_unit[r in s__r, s in s__s, t in s__t[p__mut__nuclear_unit:end]],v__on_down__nuclear_unit[r,s,t]<=v__on__nuclear_unit[r,s,t]-sum(v__on_up__nuclear_unit[r,s,t-tk] for tk in 1:p__mut__nuclear_unit-1))

@constraint(model,c__capacity_min__nuclear_unit[r in s__r, s in s__s, t in s__t],p__capacity_min__nuclear_unit*p__existing_units__nuclear_unit*v__on__nuclear_unit[r,s,t]<=v__flow__nuclear_unit[r,s,t])
@constraint(model,c__capacity_max__nuclear_unit[r in s__r, s in s__s, t in s__t],v__flow__nuclear_unit[r,s,t]<=p__capacity__nuclear_unit*p__existing_units__nuclear_unit*v__on__nuclear_unit[r,s,t])

@constraint(model,c__capacity__wind_unit[r in s__r, s in s__s, t in s__t],v__flow__wind_unit[r,s,t] <= p__flow_profile__wind_unit[r][s][t]*p__capacity__wind_unit*v__investment__wind_unit)
@constraint(model,c__capacity__solar_unit[r in s__r, s in s__s, t in s__t],v__flow__solar_unit[r,s,t] <= p__flow_profile__solar_unit[r][s][t]*p__capacity__solar_unit*v__investment__solar_unit)

@constraint(model,c__storage_intra__battery[r in s__r, s in s__s, t in s__t[2:end]],v__state_intra__battery[r,s,t]==v__state_intra__battery[r,s,t-1]+p__efficiency_charge__battery*v__charge__battery[r,s,t]-v__discharge__battery[r,s,t])
@constraint(model,c__storage_inter__battery[s in s__s, a in s__a[2:end]],v__state_inter__battery[s,a]==v__state_inter__battery[s,a-1]+sum(p__weight_delta__battery[a][r]*(v__state_intra__battery[r,s,s__t[end]]-v__state_intra__battery[r,s,s__t[1]]) for r in s__r))
@constraint(model,c__storage_inter_cyclic__battery[s in s__s],v__state_inter__battery[s,s__a[1]]==v__state_inter__battery[s,s__a[end]]+sum(p__weight_delta__battery[s__a[1]][r]*(v__state_intra__battery[r,s,s__t[end]]-v__state_intra__battery[r,s,s__t[1]]) for r in s__r))

@constraint(model,c__capacity_charge__battery[r in s__r, s in s__s, t in s__t],v__charge__battery[r,s,t]<=p__capacity_charge__battery*v__investment__battery)
@constraint(model,c__capacity_discharge__battery[r in s__r, s in s__s, t in s__t],v__discharge__battery[r,s,t]<=p__capacity_discharge__battery*v__investment__battery)
@constraint(model,c__capacity_intra__battery[r in s__r, s in s__s, t in s__t],v__state_intra__battery[r,s,t]<=p__capacity__battery*v__investment__battery)
@constraint(model,c__capacity_inter__battery[s in s__s, a in s__a],v__state_inter__battery[s,a]<=p__capacity__battery*v__investment__battery)

JuMP.optimize!(model)

println(JuMP.termination_status(model))

println(JuMP.objective_value(model))

println(JuMP.value(v__flow__gas_unit_out))

println(JuMP.value(v__flow__nuclear_unit))

println(JuMP.value(v__state_inter__battery))
println(JuMP.value(v__state_intra__battery))

# window 2

model = JuMP.Model(HiGHS.Optimizer)

p__flow_profile__gas_demand = Dict(r=>Dict(t => 100.0 for t in s__t_gas) for r in s__r)
p__flow_profile__electricity_demand = Dict(r=>Dict(t => 100.0 for t in s__t) for r in s__r)

p__existing_units__battery = JuMP.value(v__investment__battery)
p__existing_units__gas_unit = JuMP.value(v__investment__gas_unit)
p__existing_units__nuclear_unit = JuMP.value(v__investment__nuclear_unit)
p__existing_units__wind_unit = JuMP.value(v__investment__wind_unit)
p__existing_units__solar_unit = JuMP.value(v__investment__solar_unit)

@variable(model,0<=v__flow__gas_import[s__r,s__s,s__t_gas]<=p__capacity__gas_import*p__existing_units__gas_import)
@variable(model,0<=v__flow__electricity_import[s__r,s__s,s__t]<=p__capacity__electricity_import*p__existing_units__electricity_import)

@variable(model,v__investment__nuclear_unit>=p__existing_units__nuclear_unit)
@variable(model,v__flow__nuclear_unit[s__r,s__s,s__t])
@variable(model,v__on__nuclear_unit[s__r,s__s,s__t],Bin)
@variable(model,v__on_up__nuclear_unit[s__r,s__s,s__t],Bin)
@variable(model,v__on_down__nuclear_unit[s__r,s__s,s__t],Bin)

@variable(model,v__investment__gas_unit>=p__existing_units__gas_unit)
@variable(model,0<=v__flow__gas_unit_in[s__r,s__s,s__t_gas])
@variable(model,0<=v__flow__gas_unit_out[s__r,s__s,s__t])

@variable(model,v__investment__wind_unit>=p__existing_units__wind_unit)
@variable(model,0<=v__flow__wind_unit[s__r,s__s,s__t])
@variable(model,v__investment__solar_unit>=p__existing_units__solar_unit)
@variable(model,0<=v__flow__solar_unit[s__r,s__s,s__t])

@variable(model,v__investment__battery>=p__existing_units__battery)
@variable(model,0<=v__state_intra__battery[s__r,s__s,s__t])
@variable(model,0<=v__state_inter__battery[s__s,s__a])
@variable(model,0<=v__charge__battery[s__r,s__s,s__t])
@variable(model,0<=v__discharge__battery[s__r,s__s,s__t])

@variable(model,v__flow__gas_distribution_in[s__r,s__s,s__t_gas])
@variable(model,0<=v__flow__gas_distribution_out[s__r,s__s,s__t_gas]<=p__capacity__gas_distribution*p__existing_units__gas_distribution)
@variable(model,v__flow__electricity_distribution_in[s__r,s__s,s__t])
@variable(model,0<=v__flow__electricity_distribution_out[s__r,s__s,s__t]<=p__capacity__electricity_distribution*p__existing_units__electricity_distribution)
@variable(model,v__flow__electricity_transport_in[s__r,s__s,s__t])
@variable(model,0<=v__flow__electricity_transport_out[s__r,s__s,s__t]<=p__capacity__electricity_transport*p__existing_units__electricity_transport)

@objective(model,Min,sum(p__weight_economic[r]*sum(sum(p__commodity_price__gas_import[r][s][t]*v__flow__gas_import[r,s,t] for t in s__t_gas)+sum(p__commodity_price__electricity_import[r][s][t]*v__flow__electricity_import[r,s,t] + p__startup_cost__nuclear_unit*v__on_up__nuclear_unit[r,s,t]+p__commodity_price__nuclear_unit*v__flow__nuclear_unit[r,s,t] for t in s__t) for s in s__s) for r in s__r) + p__investment_cost__nuclear_unit*(v__investment__nuclear_unit-p__existing_units__nuclear_unit) + p__investment_cost__gas_unit*(v__investment__gas_unit-p__existing_units__gas_unit) + p__investment_cost__solar_unit*(v__investment__solar_unit-p__existing_units__solar_unit) + p__investment_cost__wind_unit*(v__investment__wind_unit-p__existing_units__wind_unit) + p__investment_cost__battery*(v__investment__battery-p__existing_units__battery))

@constraint(model,c__balance__gas_demand[r in s__r, s in s__s, t in s__t_gas],p__flow_profile__gas_demand[r][t] == v__flow__gas_distribution_out[r,s,t])
@constraint(model,c__balance__gas_hub[r in s__r, s in s__s, t in s__t_gas],v__flow__gas_import[r,s,t] == v__flow__gas_distribution_in[r,s,t]+v__flow__gas_unit_in[r,s,t])
@constraint(model,c__balance__electricity_demand[r in s__r, s in s__s, t in s__t],p__flow_profile__electricity_demand[r][t] == v__flow__electricity_distribution_out[r,s,t]+v__flow__solar_unit[r,s,t])
@constraint(model,c__balance__electricity_hub[r in s__r, s in s__s, t in s__t],v__flow__electricity_distribution_out[r,s,t]+v__charge__battery[r,s,t] == v__flow__electricity_transport_out[r,s,t] + v__flow__gas_unit_out[r,s,t] + v__flow__nuclear_unit[r,s,t]+p__efficiency_discharge__battery*v__discharge__battery[r,s,t])
@constraint(model,c__balance__remote_electricity_hub[r in s__r, s in s__s, t in s__t],v__flow__electricity_transport_in[r,s,t] == v__flow__electricity_import[r,s,t] + v__flow__wind_unit[r,s,t])

@constraint(model,c__efficiency__gas_distribution[r in s__r, s in s__s, t in s__t_gas], v__flow__gas_distribution_out[r,s,t]==p__efficiency__gas_distribution*v__flow__gas_distribution_in[r,s,t])
@constraint(model,c__efficiency__electricity_distribution[r in s__r, s in s__s, t in s__t], v__flow__electricity_distribution_out[r,s,t]==p__efficiency__electricity_distribution*v__flow__electricity_distribution_in[r,s,t])
@constraint(model,c__efficiency__electricity_transport[r in s__r, s in s__s, t in s__t], v__flow__electricity_transport_out[r,s,t]==p__efficiency__electricity_transport*v__flow__electricity_transport_in[r,s,t])

@constraint(model,c__efficiency__gas_unit[r in s__r, s in s__s, t in s__t_gas],sum(v__flow__gas_unit_out[r,s,t_in_gas] for t_in_gas in s__t_in_gas[t])==dt__gas*p__efficiency__gas_unit*v__flow__gas_unit_in[r,s,t])
@constraint(model,c__capacity__gas_unit_in[r in s__r, s in s__s, t in s__t_gas],v__flow__gas_unit_in[r,s,t] <= (p__capacity__gas_unit/p__efficiency__gas_unit)*v__investment__gas_unit)
@constraint(model,c__capacity__gas_unit_out[r in s__r, s in s__s, t in s__t],v__flow__gas_unit_out[r,s,t] <= p__capacity__gas_unit*v__investment__gas_unit)

@constraint(model,c__on__nuclear_unit[r in s__r, s in s__s, t in s__t[2:end]],v__on__nuclear_unit[r,s,t]==v__on__nuclear_unit[r,s,t-1]+v__on_up__nuclear_unit[r,s,t]-v__on_down__nuclear_unit[r,s,t])
@constraint(model,c__on_up__nuclear_unit[r in s__r, s in s__s, t in s__t[p__mdt__nuclear_unit:end]],v__on_up__nuclear_unit[r,s,t]<=1-v__on__nuclear_unit[r,s,t]-sum(v__on_down__nuclear_unit[r,s,t-tk] for tk in 1:p__mdt__nuclear_unit-1))
@constraint(model,c__on_down__nuclear_unit[r in s__r, s in s__s, t in s__t[p__mut__nuclear_unit:end]],v__on_down__nuclear_unit[r,s,t]<=v__on__nuclear_unit[r,s,t]-sum(v__on_up__nuclear_unit[r,s,t-tk] for tk in 1:p__mut__nuclear_unit-1))

@constraint(model,c__capacity_min__nuclear_unit[r in s__r, s in s__s, t in s__t],p__capacity_min__nuclear_unit*p__existing_units__nuclear_unit*v__on__nuclear_unit[r,s,t]<=v__flow__nuclear_unit[r,s,t])
@constraint(model,c__capacity_max__nuclear_unit[r in s__r, s in s__s, t in s__t],v__flow__nuclear_unit[r,s,t]<=p__capacity__nuclear_unit*p__existing_units__nuclear_unit*v__on__nuclear_unit[r,s,t])

@constraint(model,c__capacity__wind_unit[r in s__r, s in s__s, t in s__t],v__flow__wind_unit[r,s,t] <= p__flow_profile__wind_unit[r][s][t]*p__capacity__wind_unit*v__investment__wind_unit)
@constraint(model,c__capacity__solar_unit[r in s__r, s in s__s, t in s__t],v__flow__solar_unit[r,s,t] <= p__flow_profile__solar_unit[r][s][t]*p__capacity__solar_unit*v__investment__solar_unit)

@constraint(model,c__storage_intra__battery[r in s__r, s in s__s, t in s__t[2:end]],v__state_intra__battery[r,s,t]==v__state_intra__battery[r,s,t-1]+p__efficiency_charge__battery*v__charge__battery[r,s,t]-v__discharge__battery[r,s,t])
@constraint(model,c__storage_inter__battery[s in s__s, a in s__a[2:end]],v__state_inter__battery[s,a]==v__state_inter__battery[s,a-1]+sum(p__weight_delta__battery[a][r]*(v__state_intra__battery[r,s,s__t[end]]-v__state_intra__battery[r,s,s__t[1]]) for r in s__r))
@constraint(model,c__storage_inter_cyclic__battery[s in s__s],v__state_inter__battery[s,s__a[1]]==v__state_inter__battery[s,s__a[end]]+sum(p__weight_delta__battery[s__a[1]][r]*(v__state_intra__battery[r,s,s__t[end]]-v__state_intra__battery[r,s,s__t[1]]) for r in s__r))

@constraint(model,c__capacity_charge__battery[r in s__r, s in s__s, t in s__t],v__charge__battery[r,s,t]<=p__capacity_charge__battery*v__investment__battery)
@constraint(model,c__capacity_discharge__battery[r in s__r, s in s__s, t in s__t],v__discharge__battery[r,s,t]<=p__capacity_discharge__battery*v__investment__battery)
@constraint(model,c__capacity_intra__battery[r in s__r, s in s__s, t in s__t],v__state_intra__battery[r,s,t]<=p__capacity__battery*v__investment__battery)
@constraint(model,c__capacity_inter__battery[s in s__s, a in s__a],v__state_inter__battery[s,a]<=p__capacity__battery*v__investment__battery)

JuMP.optimize!(model)

println(JuMP.termination_status(model))

println(JuMP.objective_value(model))

println(JuMP.value(v__flow__gas_unit_out))

println(JuMP.value(v__flow__nuclear_unit))

println(JuMP.value(v__state_inter__battery))
println(JuMP.value(v__state_intra__battery))