import JuMP
using JuMP:@variable, @objective, @constraint
import HiGHS

model = JuMP.Model(HiGHS.Optimizer)

s__t = 1:10
s__s = [:cheap_low,:cheap_high,:expensive_low,:expensive_high]

p__weight = Dict(s => 0.25 for s in s__s)

p__commodity_price__cheap_source = Dict(
    :cheap_low => [1.0 for t in s__t],
    :cheap_high => [1.0 for t in s__t],
    :expensive_low => [20.0 for t in s__t],
    :expensive_high => [20.0 for t in s__t]
)
p__commodity_price__expensive_source = [10.0 for t in s__t]
p__flow_profile__demand = Dict(
    :cheap_low => [10.0 for t in s__t],
    :cheap_high => [60.0 for t in s__t],
    :expensive_low => [10.0 for t in s__t],
    :expensive_high => [60.0 for t in s__t]
)
p__efficiency__cheap_link = 0.8
p__efficiency__expensive_link = 0.8
p__efficiency__triangle = 0.8
p__efficiency__cheap_unit = 0.4
p__efficiency__expensive_unit = 0.4
p__capacity__cheap_link = 100.0
p__existing_units__cheap_link = 1.0
p__capacity__expensive_link = 100.0
p__existing_units__expensive_link = 1.0
p__capacity__triangle = 100.0
p__existing_units__triangle = 1.0
p__capacity__cheap_unit = 50.0
p__existing_units__cheap_unit = 1.0
p__capacity__expensive_unit = 50.0
p__existing_units__expensive_unit = 1.0

@variable(model,0<=v__flow__cheap_link_in[s__t,s__s])
@variable(model,0<=v__flow__cheap_link_out[s__t,s__s]<=p__capacity__cheap_link*p__existing_units__cheap_link)
@variable(model,0<=v__flow__expensive_link_in[s__t,s__s])
@variable(model,0<=v__flow__expensive_link_out[s__t,s__s]<=p__capacity__expensive_link*p__existing_units__expensive_link)
@variable(model,0<=v__flow__triangle_in[s__t,s__s])
@variable(model,0<=v__flow__triangle_out[s__t,s__s]<=p__capacity__triangle*p__existing_units__triangle)
@variable(model,0<=v__flow__cheap_source[s__t,s__s])
@variable(model,0<=v__flow__cheap_supply[s__t,s__s]<=p__capacity__cheap_unit*p__existing_units__cheap_unit)
@variable(model,0<=v__flow__expensive_source[s__t,s__s])
@variable(model,0<=v__flow__expensive_supply[s__t,s__s]<=p__capacity__expensive_unit*p__existing_units__expensive_unit)

@objective(model,Min,sum(p__weight[s]*sum(p__commodity_price__cheap_source[s][t]*v__flow__cheap_source[t,s]+p__commodity_price__expensive_source[t]*v__flow__expensive_source[t,s] for t in s__t) for s in s__s))

@constraint(model,c__balance__demand[t in s__t,s in s__s],p__flow_profile__demand[s][t] == v__flow__cheap_link_out[t,s]+v__flow__expensive_link_out[t,s])

@constraint(model,c__efficiency__cheap_link[t in s__t,s in s__s], v__flow__cheap_link_out[t,s]==p__efficiency__cheap_link*v__flow__cheap_link_in[t,s])

@constraint(model,c__efficiency__expensive_link[t in s__t,s in s__s],v__flow__expensive_link_out[t,s]==p__efficiency__expensive_link*v__flow__expensive_link_in[t,s])

@constraint(model,c__efficiency__triangle[t in s__t,s in s__s], v__flow__triangle_out[t,s]==p__efficiency__triangle*v__flow__triangle_in[t,s])

@constraint(model,c__balance__cheap_supply[t in s__t,s in s__s],v__flow__cheap_supply[t,s]+v__flow__triangle_out[t,s]==v__flow__cheap_link_in[t,s])

@constraint(model,c__balance__expensive_supply[t in s__t,s in s__s],v__flow__expensive_supply[t,s]==v__flow__expensive_link_in[t,s]+v__flow__triangle_in[t,s])

@constraint(model,c__efficiency__cheap_unit[t in s__t,s in s__s],v__flow__cheap_supply[t,s]==p__efficiency__cheap_unit*v__flow__cheap_source[t,s])

@constraint(model,c__efficiency__expensive_unit[t in s__t,s in s__s], v__flow__expensive_supply[t,s]==p__efficiency__expensive_unit*v__flow__expensive_source[t,s])

JuMP.optimize!(model)

println(JuMP.termination_status(model))

println(JuMP.objective_value(model))

println(JuMP.value(v__flow__cheap_source))

println(JuMP.value(v__flow__expensive_source))