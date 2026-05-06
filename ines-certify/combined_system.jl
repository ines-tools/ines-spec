import JuMP
using JuMP:@variable, @objective, @constraint
import HiGHS

# window 1

model = JuMP.Model(HiGHS.Optimizer)

s__t = [t for t in 1:10]
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
ps__wind = repeat([0, 1],Int(length(s__t)/2))#[rand(1)[1] for t in s__t]
ps__factor_wind = Dict(
    :cheap_low => ps__wind,
    :cheap_high => (ps__wind .+ 0.25)/1.25,
    :expensive_low => ps__wind,
    :expensive_high => (ps__wind .+ 0.25)/1.25
)
ps__solar = [round((sin(pi/2*t)+1)/2;digits=2) for t in s__t]
ps__factor_solar = Dict(
    :cheap_low => ps__solar,
    :cheap_high => (ps__solar .+ 0.25)/1.25,
    :expensive_low => ps__solar,
    :expensive_high => (ps__solar .+ 0.25)/1.25
)

p__weight = Dict(s=>0.25 for s in s__s)

p__commodity_price__gas_import = Dict(s=> Dict(t => 10.0*ps__factor_price[s] for t in s__t_gas) for s in s__s)
p__capacity__gas_import = 1000.0
p__existing_units__gas_import = 1.0

p__commodity_price__electricity_import = Dict(s=> Dict(t => 40.0*ps__factor_price[s] for t in s__t) for s in s__s)
p__capacity__electricity_import = 10.0
p__existing_units__electricity_import = 1.0

p__flow_profile__gas_demand = Dict(t => 60.0 for t in s__t_gas)
p__flow_profile__electricity_demand = Dict(t => 60.0 for t in s__t)
p__reserve__electricity_demand = Dict(t => 10.0 for t in s__t)
p__penalty__electricity_demand = 1000.0

p__efficiency__gas_distribution = 0.8
p__capacity__gas_distribution = 1000.0
p__existing_units__gas_distribution = 1.0
p__efficiency__electricity_distribution = 0.8
p__capacity__electricity_distribution = 1000.0
p__existing_units__electricity_distribution = 1.0
p__efficiency__electricity_transport = 0.8
p__capacity__electricity_transport = 1000.0
p__existing_units__electricity_transport = 1.0

p__commodity_price__nuclear_unit = 40.0
p__startup_cost__nuclear_unit = 40.0
p__existing_units__nuclear_unit = 1.0
#p__capacity_min__nuclear_unit = 10.0
p__capacity__nuclear_unit = 20.0
p__mut__nuclear_unit = 2
p__mdt__nuclear_unit = 1
p__procurement_cost__nuclear_unit = 2.0
p__max_reserve__nuclear_unit = 2.0

p__efficiency__gas_unit = 0.4
p__investment_cost__gas_unit = 600.0
p__existing_units__gas_unit = 0.0
p__capacity__gas_unit = 10.0
p__procurement_cost__gas_unit = 4.0
p__max_reserve__gas_unit = 4.0

p__flow_profile__wind_unit = Dict(s=> Dict(t => ps__factor_wind[s][t] for t in s__t) for s in s__s)
p__investment_cost__wind_unit = 200.0
p__existing_units__wind_unit = 0.0
p__capacity__wind_unit = 10.0

p__flow_profile__solar_unit = Dict(s=> Dict(t => ps__factor_solar[s][t] for t in s__t) for s in s__s)
p__investment_cost__solar_unit = 200.0
p__existing_units__solar_unit = 0.0
p__capacity__solar_unit = 10.0

p__investment_cost__battery = 800.0
p__capacity__battery = 20.0
p__existing_units__battery = 0.0
p__capacity_charge__battery = 100.0
p__capacity_discharge__battery = 100.0
p__efficiency__battery = 1.0
p__efficiency_charge__battery = 1.0
p__efficiency_discharge__battery = 1.0

@variable(model,0<=v__slack__electricity_demand[s__s,s__t])
@variable(model,0<=v__flow_reserve__nuclear_unit[s__s,s__t]<=p__max_reserve__nuclear_unit*p__existing_units__nuclear_unit)
@variable(model,0<=v__flow_reserve__gas_unit[s__s,s__t])


@variable(model,0<=v__flow__gas_import[s__s,s__t_gas]<=p__capacity__gas_import*p__existing_units__gas_import)
@variable(model,0<=v__flow__electricity_import[s__s,s__t]<=p__capacity__electricity_import*p__existing_units__electricity_import)

@variable(model,0<=v__flow__nuclear_unit[s__s,s__t])
@variable(model,v__on__nuclear_unit[s__s,s__t],Bin)
@variable(model,v__on_up__nuclear_unit[s__s,s__t],Bin)
@variable(model,v__on_down__nuclear_unit[s__s,s__t],Bin)

@variable(model,v__investment__gas_unit>=p__existing_units__gas_unit)
@variable(model,0<=v__flow__gas_unit_in[s__s,s__t_gas])
@variable(model,0<=v__flow__gas_unit_out[s__s,s__t])

@variable(model,v__investment__wind_unit>=p__existing_units__wind_unit)
@variable(model,0<=v__flow__wind_unit[s__s,s__t])
@variable(model,v__investment__solar_unit>=p__existing_units__solar_unit)
@variable(model,0<=v__flow__solar_unit[s__s,s__t])

@variable(model,v__investment__battery>=p__existing_units__battery)
@variable(model,0<=v__state__battery[s__s,s__t])
@variable(model,0<=v__charge__battery[s__s,s__t])
@variable(model,0<=v__discharge__battery[s__s,s__t])

@variable(model,v__flow__gas_distribution_in[s__s,s__t_gas])
@variable(model,0<=v__flow__gas_distribution_out[s__s,s__t_gas]<=p__capacity__gas_distribution*p__existing_units__gas_distribution)
@variable(model,v__flow__electricity_distribution_in[s__s,s__t])
@variable(model,0<=v__flow__electricity_distribution_out[s__s,s__t]<=p__capacity__electricity_distribution*p__existing_units__electricity_distribution)
@variable(model,v__flow__electricity_transport_in[s__s,s__t])
@variable(model,0<=v__flow__electricity_transport_out[s__s,s__t]<=p__capacity__electricity_transport*p__existing_units__electricity_transport)

@objective(model,Min,sum(p__weight[s]*sum(p__commodity_price__gas_import[s][t]*v__flow__gas_import[s,t] for t in s__t_gas)+p__weight[s]*sum(p__commodity_price__electricity_import[s][t]*v__flow__electricity_import[s,t] + p__startup_cost__nuclear_unit*v__on_up__nuclear_unit[s,t]+p__commodity_price__nuclear_unit*v__flow__nuclear_unit[s,t] +p__penalty__electricity_demand*v__slack__electricity_demand[s,t]+p__procurement_cost__nuclear_unit*v__flow_reserve__nuclear_unit[s,t]+p__procurement_cost__gas_unit*v__flow_reserve__gas_unit[s,t] for t in s__t) for s in s__s) + p__investment_cost__gas_unit*(v__investment__gas_unit-p__existing_units__gas_unit) + p__investment_cost__solar_unit*(v__investment__solar_unit-p__existing_units__solar_unit) + p__investment_cost__wind_unit*(v__investment__wind_unit-p__existing_units__wind_unit) + p__investment_cost__battery*(v__investment__battery-p__existing_units__battery))

@constraint(model,c__reserve_balance[s in s__s, t in s__t],p__reserve__electricity_demand[t]<=v__flow_reserve__nuclear_unit[s,t]+v__flow_reserve__gas_unit[s,t]+v__slack__electricity_demand[s,t])
@constraint(model,c__reserve_capacity__nuclear_unit[s in s__s,t in s__t],v__flow__nuclear_unit[s,t]+v__flow_reserve__nuclear_unit[s,t]<=p__capacity__nuclear_unit*p__existing_units__nuclear_unit*v__on__nuclear_unit[s,t])
@constraint(model,c__reserve_capacity__gas_unit[s in s__s,t in s__t],v__flow__gas_unit_out[s,t]+v__flow_reserve__gas_unit[s,t]<=p__capacity__gas_unit*v__investment__gas_unit)
@constraint(model,c__reserve_limit__gas_unit[s in s__s,t in s__t],v__flow_reserve__gas_unit[s,t]<=p__max_reserve__gas_unit*v__investment__gas_unit)

@constraint(model,c__balance__gas_demand[s in s__s, t in s__t_gas],p__flow_profile__gas_demand[t] == v__flow__gas_distribution_out[s,t])
@constraint(model,c__balance__gas_hub[s in s__s, t in s__t_gas],v__flow__gas_import[s,t] == v__flow__gas_distribution_in[s,t]+v__flow__gas_unit_in[s,t])
@constraint(model,c__balance__electricity_demand[s in s__s, t in s__t],p__flow_profile__electricity_demand[t] == v__flow__electricity_distribution_out[s,t]+v__flow__solar_unit[s,t])
@constraint(model,c__balance__electricity_hub[s in s__s, t in s__t],v__flow__electricity_distribution_out[s,t]+v__charge__battery[s,t] == v__flow__electricity_transport_out[s,t] + v__flow__gas_unit_out[s,t] + v__flow__nuclear_unit[s,t]+p__efficiency_discharge__battery*v__discharge__battery[s,t])
@constraint(model,c__balance__remote_electricity_hub[s in s__s, t in s__t],v__flow__electricity_transport_in[s,t] == v__flow__electricity_import[s,t] + v__flow__wind_unit[s,t])

@constraint(model,c__efficiency__gas_distribution[s in s__s, t in s__t_gas], v__flow__gas_distribution_out[s,t]==p__efficiency__gas_distribution*v__flow__gas_distribution_in[s,t])
@constraint(model,c__efficiency__electricity_distribution[s in s__s, t in s__t], v__flow__electricity_distribution_out[s,t]==p__efficiency__electricity_distribution*v__flow__electricity_distribution_in[s,t])
@constraint(model,c__efficiency__electricity_transport[s in s__s, t in s__t], v__flow__electricity_transport_out[s,t]==p__efficiency__electricity_transport*v__flow__electricity_transport_in[s,t])

@constraint(model,c__efficiency__gas_unit[s in s__s, t in s__t_gas],sum(v__flow__gas_unit_out[s,t_in_gas] for t_in_gas in s__t_in_gas[t])==dt__gas*p__efficiency__gas_unit*v__flow__gas_unit_in[s,t])
@constraint(model,c__capacity__gas_unit_in[s in s__s, t in s__t_gas],v__flow__gas_unit_in[s,t] <= (p__capacity__gas_unit/p__efficiency__gas_unit)*v__investment__gas_unit)
@constraint(model,c__capacity__gas_unit_out[s in s__s, t in s__t],v__flow__gas_unit_out[s,t] <= p__capacity__gas_unit*v__investment__gas_unit)

@constraint(model,c__on__nuclear_unit[s in s__s, t in s__t[2:end]],v__on__nuclear_unit[s,t]==v__on__nuclear_unit[s,t-1]+v__on_up__nuclear_unit[s,t]-v__on_down__nuclear_unit[s,t])
@constraint(model,c__on_up__nuclear_unit[s in s__s, t in s__t[p__mdt__nuclear_unit:end]],v__on_up__nuclear_unit[s,t]<=1-v__on__nuclear_unit[s,t]-sum(v__on_down__nuclear_unit[s,t-tk] for tk in 1:p__mdt__nuclear_unit-1))
@constraint(model,c__on_down__nuclear_unit[s in s__s, t in s__t[p__mut__nuclear_unit:end]],v__on_down__nuclear_unit[s,t]<=v__on__nuclear_unit[s,t]-sum(v__on_up__nuclear_unit[s,t-tk] for tk in 1:p__mut__nuclear_unit-1))

#@constraint(model,c__capacity_min__nuclear_unit[s in s__s, t in s__t],p__capacity_min__nuclear_unit*p__existing_units__nuclear_unit*v__on__nuclear_unit[s,t]<=v__flow__nuclear_unit[s,t])
#@constraint(model,c__capacity_max__nuclear_unit[s in s__s, t in s__t],v__flow__nuclear_unit[s,t]<=p__capacity__nuclear_unit*p__existing_units__nuclear_unit*v__on__nuclear_unit[s,t])

@constraint(model,c__capacity__wind_unit[s in s__s, t in s__t],v__flow__wind_unit[s,t] <= p__flow_profile__wind_unit[s][t]*p__capacity__wind_unit*v__investment__wind_unit)
@constraint(model,c__capacity__solar_unit[s in s__s, t in s__t],v__flow__solar_unit[s,t] <= p__flow_profile__solar_unit[s][t]*p__capacity__solar_unit*v__investment__solar_unit)

@constraint(model,c__storage__battery[s in s__s, t in s__t[2:end]],v__state__battery[s,t]==p__efficiency__battery*v__state__battery[s,t-1]+p__efficiency_charge__battery*v__charge__battery[s,t]-v__discharge__battery[s,t])
#@constraint(model,c__storage_cyclic__battery[s in s__s],v__state__battery[s,s__t[1]]==p__efficiency__battery*v__state__battery[s,s__t[end]]+p__efficiency_charge__battery*v__charge__battery[s,s__t[1]]-v__discharge__battery[s,s__t[1]])
@constraint(model,c__storage_init__battery[s in s__s],v__state__battery[s,s__t[1]]==p__efficiency_charge__battery*v__charge__battery[s,s__t[1]]-v__discharge__battery[s,s__t[1]])

@constraint(model,c__capacity_charge__battery[s in s__s, t in s__t],v__charge__battery[s,t]<=p__capacity_charge__battery*v__investment__battery)
@constraint(model,c__capacity_discharge__battery[s in s__s, t in s__t],v__discharge__battery[s,t]<=p__capacity_discharge__battery*v__investment__battery)
@constraint(model,c__capacity__battery[s in s__s, t in s__t],v__state__battery[s,t]<=p__capacity__battery*v__investment__battery)

JuMP.optimize!(model)

println(JuMP.termination_status(model))

println(JuMP.objective_value(model))

println(JuMP.value(v__flow__gas_unit_out))

println(JuMP.value(v__flow__nuclear_unit))

println(JuMP.value(v__state__battery))

# window 2

model = JuMP.Model(HiGHS.Optimizer)

p__flow_profile__gas_demand = Dict(t => 100.0 for t in s__t_gas)
p__flow_profile__electricity_demand = Dict(t => 100.0 for t in s__t)

#solar needs to be shifted to continue the pattern in the second window
ps__solar = [round((sin(pi/2*(t+2))+1)/2;digits=2) for t in s__t]
ps__factor_solar = Dict(
    :cheap_low => ps__solar,
    :cheap_high => (ps__solar .+ 0.25)/1.25,
    :expensive_low => ps__solar,
    :expensive_high => (ps__solar .+ 0.25)/1.25
)
p__flow_profile__solar_unit = Dict(s=> Dict(t => ps__factor_solar[s][t] for t in s__t) for s in s__s)

p__existing_units__battery = JuMP.value(v__investment__battery)
p__existing_units__gas_unit = JuMP.value(v__investment__gas_unit)
p__existing_units__wind_unit = JuMP.value(v__investment__wind_unit)
p__existing_units__solar_unit = JuMP.value(v__investment__solar_unit)

@variable(model,0<=v__slack__electricity_demand[s__s,s__t])
@variable(model,0<=v__flow_reserve__nuclear_unit[s__s,s__t]<=p__max_reserve__nuclear_unit*p__existing_units__nuclear_unit)
@variable(model,0<=v__flow_reserve__gas_unit[s__s,s__t])


@variable(model,0<=v__flow__gas_import[s__s,s__t_gas]<=p__capacity__gas_import*p__existing_units__gas_import)
@variable(model,0<=v__flow__electricity_import[s__s,s__t]<=p__capacity__electricity_import*p__existing_units__electricity_import)

@variable(model,0<=v__flow__nuclear_unit[s__s,s__t])
@variable(model,v__on__nuclear_unit[s__s,s__t],Bin)
@variable(model,v__on_up__nuclear_unit[s__s,s__t],Bin)
@variable(model,v__on_down__nuclear_unit[s__s,s__t],Bin)

@variable(model,v__investment__gas_unit>=p__existing_units__gas_unit)
@variable(model,0<=v__flow__gas_unit_in[s__s,s__t_gas])
@variable(model,0<=v__flow__gas_unit_out[s__s,s__t])

@variable(model,v__investment__wind_unit>=p__existing_units__wind_unit)
@variable(model,0<=v__flow__wind_unit[s__s,s__t])
@variable(model,v__investment__solar_unit>=p__existing_units__solar_unit)
@variable(model,0<=v__flow__solar_unit[s__s,s__t])

@variable(model,v__investment__battery>=p__existing_units__battery)
@variable(model,0<=v__state__battery[s__s,s__t])
@variable(model,0<=v__charge__battery[s__s,s__t])
@variable(model,0<=v__discharge__battery[s__s,s__t])

@variable(model,v__flow__gas_distribution_in[s__s,s__t_gas])
@variable(model,0<=v__flow__gas_distribution_out[s__s,s__t_gas]<=p__capacity__gas_distribution*p__existing_units__gas_distribution)
@variable(model,v__flow__electricity_distribution_in[s__s,s__t])
@variable(model,0<=v__flow__electricity_distribution_out[s__s,s__t]<=p__capacity__electricity_distribution*p__existing_units__electricity_distribution)
@variable(model,v__flow__electricity_transport_in[s__s,s__t])
@variable(model,0<=v__flow__electricity_transport_out[s__s,s__t]<=p__capacity__electricity_transport*p__existing_units__electricity_transport)

@objective(model,Min,sum(p__weight[s]*sum(p__commodity_price__gas_import[s][t]*v__flow__gas_import[s,t] for t in s__t_gas)+p__weight[s]*sum(p__commodity_price__electricity_import[s][t]*v__flow__electricity_import[s,t] + p__startup_cost__nuclear_unit*v__on_up__nuclear_unit[s,t]+p__commodity_price__nuclear_unit*v__flow__nuclear_unit[s,t] +p__penalty__electricity_demand*v__slack__electricity_demand[s,t]+p__procurement_cost__nuclear_unit*v__flow_reserve__nuclear_unit[s,t]+p__procurement_cost__gas_unit*v__flow_reserve__gas_unit[s,t] for t in s__t) for s in s__s) + p__investment_cost__gas_unit*(v__investment__gas_unit-p__existing_units__gas_unit) + p__investment_cost__solar_unit*(v__investment__solar_unit-p__existing_units__solar_unit) + p__investment_cost__wind_unit*(v__investment__wind_unit-p__existing_units__wind_unit) + p__investment_cost__battery*(v__investment__battery-p__existing_units__battery))

@constraint(model,c__reserve_balance[s in s__s, t in s__t],p__reserve__electricity_demand[t]<=v__flow_reserve__nuclear_unit[s,t]+v__flow_reserve__gas_unit[s,t]+v__slack__electricity_demand[s,t])
@constraint(model,c__reserve_capacity__nuclear_unit[s in s__s,t in s__t],v__flow__nuclear_unit[s,t]+v__flow_reserve__nuclear_unit[s,t]<=p__capacity__nuclear_unit*p__existing_units__nuclear_unit*v__on__nuclear_unit[s,t])
@constraint(model,c__reserve_capacity__gas_unit[s in s__s,t in s__t],v__flow__gas_unit_out[s,t]+v__flow_reserve__gas_unit[s,t]<=p__capacity__gas_unit*v__investment__gas_unit)
@constraint(model,c__reserve_limit__gas_unit[s in s__s,t in s__t],v__flow_reserve__gas_unit[s,t]<=p__max_reserve__gas_unit*v__investment__gas_unit)

@constraint(model,c__balance__gas_demand[s in s__s, t in s__t_gas],p__flow_profile__gas_demand[t] == v__flow__gas_distribution_out[s,t])
@constraint(model,c__balance__gas_hub[s in s__s, t in s__t_gas],v__flow__gas_import[s,t] == v__flow__gas_distribution_in[s,t]+v__flow__gas_unit_in[s,t])
@constraint(model,c__balance__electricity_demand[s in s__s, t in s__t],p__flow_profile__electricity_demand[t] == v__flow__electricity_distribution_out[s,t]+v__flow__solar_unit[s,t])
@constraint(model,c__balance__electricity_hub[s in s__s, t in s__t],v__flow__electricity_distribution_out[s,t]+v__charge__battery[s,t] == v__flow__electricity_transport_out[s,t] + v__flow__gas_unit_out[s,t] + v__flow__nuclear_unit[s,t]+p__efficiency_discharge__battery*v__discharge__battery[s,t])
@constraint(model,c__balance__remote_electricity_hub[s in s__s, t in s__t],v__flow__electricity_transport_in[s,t] == v__flow__electricity_import[s,t] + v__flow__wind_unit[s,t])

@constraint(model,c__efficiency__gas_distribution[s in s__s, t in s__t_gas], v__flow__gas_distribution_out[s,t]==p__efficiency__gas_distribution*v__flow__gas_distribution_in[s,t])
@constraint(model,c__efficiency__electricity_distribution[s in s__s, t in s__t], v__flow__electricity_distribution_out[s,t]==p__efficiency__electricity_distribution*v__flow__electricity_distribution_in[s,t])
@constraint(model,c__efficiency__electricity_transport[s in s__s, t in s__t], v__flow__electricity_transport_out[s,t]==p__efficiency__electricity_transport*v__flow__electricity_transport_in[s,t])

@constraint(model,c__efficiency__gas_unit[s in s__s, t in s__t_gas],sum(v__flow__gas_unit_out[s,t_in_gas] for t_in_gas in s__t_in_gas[t])==dt__gas*p__efficiency__gas_unit*v__flow__gas_unit_in[s,t])
@constraint(model,c__capacity__gas_unit_in[s in s__s, t in s__t_gas],v__flow__gas_unit_in[s,t] <= (p__capacity__gas_unit/p__efficiency__gas_unit)*v__investment__gas_unit)
#@constraint(model,c__capacity__gas_unit_out[s in s__s, t in s__t],v__flow__gas_unit_out[s,t] <= p__capacity__gas_unit*v__investment__gas_unit)

@constraint(model,c__on__nuclear_unit[s in s__s, t in s__t[2:end]],v__on__nuclear_unit[s,t]==v__on__nuclear_unit[s,t-1]+v__on_up__nuclear_unit[s,t]-v__on_down__nuclear_unit[s,t])
@constraint(model,c__on_up__nuclear_unit[s in s__s, t in s__t[p__mdt__nuclear_unit:end]],v__on_up__nuclear_unit[s,t]<=1-v__on__nuclear_unit[s,t]-sum(v__on_down__nuclear_unit[s,t-tk] for tk in 1:p__mdt__nuclear_unit-1))
@constraint(model,c__on_down__nuclear_unit[s in s__s, t in s__t[p__mut__nuclear_unit:end]],v__on_down__nuclear_unit[s,t]<=v__on__nuclear_unit[s,t]-sum(v__on_up__nuclear_unit[s,t-tk] for tk in 1:p__mut__nuclear_unit-1))

#@constraint(model,c__capacity_min__nuclear_unit[s in s__s, t in s__t],p__capacity_min__nuclear_unit*p__existing_units__nuclear_unit*v__on__nuclear_unit[s,t]<=v__flow__nuclear_unit[s,t])
#@constraint(model,c__capacity_max__nuclear_unit[s in s__s, t in s__t],v__flow__nuclear_unit[s,t]<=p__capacity__nuclear_unit*p__existing_units__nuclear_unit*v__on__nuclear_unit[s,t])

@constraint(model,c__capacity__wind_unit[s in s__s, t in s__t],v__flow__wind_unit[s,t] <= p__flow_profile__wind_unit[s][t]*p__capacity__wind_unit*v__investment__wind_unit)
@constraint(model,c__capacity__solar_unit[s in s__s, t in s__t],v__flow__solar_unit[s,t] <= p__flow_profile__solar_unit[s][t]*p__capacity__solar_unit*v__investment__solar_unit)

@constraint(model,c__storage__battery[s in s__s, t in s__t[2:end]],v__state__battery[s,t]==p__efficiency__battery*v__state__battery[s,t-1]+p__efficiency_charge__battery*v__charge__battery[s,t]-v__discharge__battery[s,t])
#@constraint(model,c__storage_cyclic__battery[s in s__s],v__state__battery[s,s__t[1]]==p__efficiency__battery*v__state__battery[s,s__t[end]]+p__efficiency_charge__battery*v__charge__battery[s,s__t[1]]-v__discharge__battery[s,s__t[1]])
@constraint(model,c__storage_init__battery[s in s__s],v__state__battery[s,s__t[1]]==p__efficiency_charge__battery*v__charge__battery[s,s__t[1]]-v__discharge__battery[s,s__t[1]])

@constraint(model,c__capacity_charge__battery[s in s__s, t in s__t],v__charge__battery[s,t]<=p__capacity_charge__battery*v__investment__battery)
@constraint(model,c__capacity_discharge__battery[s in s__s, t in s__t],v__discharge__battery[s,t]<=p__capacity_discharge__battery*v__investment__battery)
@constraint(model,c__capacity__battery[s in s__s, t in s__t],v__state__battery[s,t]<=p__capacity__battery*v__investment__battery)

JuMP.optimize!(model)

println(JuMP.termination_status(model))

println(JuMP.objective_value(model))

println(JuMP.value(v__flow__gas_unit_out))

println(JuMP.value(v__flow__nuclear_unit))

println(JuMP.value(v__state__battery))