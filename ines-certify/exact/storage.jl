import JuMP
using JuMP:@variable, @objective, @constraint
import HiGHS

model = JuMP.Model(HiGHS.Optimizer)

s__h = [h for h in 1:10] #intra
s__d = [d for d in 1:3] #inter
s__r = [r for r in 1:2] #representative

p__weight_economic = Dict( # Dict(r => weight)
    1 => 2,
    2 => 1
)
p__weight_delta__storage = Dict( # Dict(d => Dict(r => weight))
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
p__commodity_price__cheap_source = Dict(r => [1.0 for h in s__h] for r in s__r)
p__commodity_price__expensive_source = Dict(r => [10.0 for h in s__h] for r in s__r)
p__flow_profile__demand = Dict(r => [10.0 for h in s__h] for r in s__r)
p__efficiency__cheap_link = 1.0
p__efficiency__expensive_link = 1.0
p__efficiency__triangle = 1.0
p__efficiency__cheap_unit = 0.4
p__efficiency__expensive_unit = 0.4
p__capacity__cheap_link = 100.0
p__existing_units__cheap_link = 1.0
p__capacity__expensive_link = 100.0
p__existing_units__expensive_link = 1.0
p__capacity__triangle = 100.0
p__existing_units__triangle = 1.0
p__capacity__cheap_unit = 100.0
p__existing_units__cheap_unit = 1.0
p__capacity__expensive_unit = 100.0
p__existing_units__expensive_unit = 1.0
p__capacity__storage = 100.0
p__existing_units__storage = 1.0
p__capacity_charge__storage = 100.0
p__capacity_discharge__storage = 100.0
p__efficiency__storage = 0.9
p__efficiency_charge__storage = 0.7
p__efficiency_discharge__storage = 0.7

@variable(model,0<=v__flow__cheap_link_in[s__r,s__h])
@variable(model,0<=v__flow__cheap_link_out[s__r,s__h]<=p__capacity__cheap_link*p__existing_units__cheap_link)
@variable(model,0<=v__flow__expensive_link_in[s__r,s__h])
@variable(model,0<=v__flow__expensive_link_out[s__r,s__h]<=p__capacity__expensive_link*p__existing_units__expensive_link)
@variable(model,0<=v__flow__triangle_in[s__r,s__h])
@variable(model,0<=v__flow__triangle_out[s__r,s__h]<=p__capacity__triangle*p__existing_units__triangle)
@variable(model,0<=v__flow__cheap_source[s__r,s__h])
@variable(model,0<=v__flow__cheap_supply[s__r,s__h]<=p__capacity__cheap_unit*p__existing_units__cheap_unit)
@variable(model,0<=v__flow__expensive_source[s__r,s__h])
@variable(model,0<=v__flow__expensive_supply[s__r,s__h]<=p__capacity__expensive_unit*p__existing_units__expensive_unit)
@variable(model,0<=v__state_intra__storage[s__r,s__h]<=p__capacity__storage*p__existing_units__storage)
@variable(model,0<=v__state_inter__storage[s__d]<=p__capacity__storage*p__existing_units__storage)
@variable(model,0<=v__charge__storage[s__r,s__h]<=p__capacity_charge__storage*p__existing_units__storage)
@variable(model,0<=v__discharge__storage[s__r,s__h]<=p__capacity_discharge__storage*p__existing_units__storage)

@objective(model,Min,sum(p__weight_economic[r]*sum(p__commodity_price__cheap_source[r][h]*v__flow__cheap_source[r,h]+p__commodity_price__expensive_source[r][h]*v__flow__expensive_source[r,h] for h in s__h) for r in s__r))

@constraint(model,c__balance__demand[r in s__r, h in s__h],p__flow_profile__demand[r][h] == v__flow__cheap_link_out[r,h]+v__flow__expensive_link_out[r,h]-v__charge__storage[r,h]+p__efficiency_discharge__storage*v__discharge__storage[r,h])

@constraint(model,c__efficiency__cheap_link[r in s__r,h in s__h], v__flow__cheap_link_out[r,h]==p__efficiency__cheap_link*v__flow__cheap_link_in[r,h])
@constraint(model,c__efficiency__expensive_link[r in s__r,h in s__h],v__flow__expensive_link_out[r,h]==p__efficiency__expensive_link*v__flow__expensive_link_in[r,h])
@constraint(model,c__efficiency__triangle[r in s__r,h in s__h], v__flow__triangle_out[r,h]==p__efficiency__triangle*v__flow__triangle_in[r,h])

@constraint(model,c__balance__cheap_supply[r in s__r,h in s__h],v__flow__cheap_supply[r,h]+v__flow__triangle_out[r,h]==v__flow__cheap_link_in[r,h])
@constraint(model,c__balance__expensive_supply[r in s__r,h in s__h],v__flow__expensive_supply[r,h]==v__flow__expensive_link_in[r,h]+v__flow__triangle_in[r,h])

@constraint(model,c__efficiency__cheap_unit[r in s__r,h in s__h],v__flow__cheap_supply[r,h]==p__efficiency__cheap_unit*v__flow__cheap_source[r,h])
@constraint(model,c__efficiency__expensive_unit[r in s__r,h in s__h], v__flow__expensive_supply[r,h]==p__efficiency__expensive_unit*v__flow__expensive_source[r,h])

@constraint(model,c__storage_intra__storage[r in s__r,h in s__h[2:end]],v__state_intra__storage[r,h]==v__state_intra__storage[r,h-1]+p__efficiency_charge__storage*v__charge__storage[r,h]-v__discharge__storage[r,h])
@constraint(model,c__storage_inter__storage[d in s__d[2:end]],v__state_inter__storage[d]==v__state_inter__storage[d-1]+sum(p__weight_delta__storage[d][r]*(v__state_intra__storage[r,s__h[end]]-v__state_intra__storage[r,s__h[1]]) for r in s__r))
@constraint(model,c__storage_inter_cyclic__storage,v__state_inter__storage[s__d[1]]==v__state_inter__storage[s__d[end]]+sum(p__weight_delta__storage[s__d[1]][r]*(v__state_intra__storage[r,s__h[end]]-v__state_intra__storage[r,s__h[1]]) for r in s__r))

JuMP.optimize!(model)

println(JuMP.termination_status(model))

println(JuMP.objective_value(model))

println(JuMP.value(v__flow__cheap_source))

println(JuMP.value(v__flow__expensive_source))

println(JuMP.value(v__state_inter__storage))
println(JuMP.value(v__state_intra__storage))