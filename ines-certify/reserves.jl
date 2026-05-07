import JuMP
using JuMP:@variable, @objective, @constraint
import HiGHS

model = JuMP.Model(HiGHS.Optimizer)

s__t = 1:10

p__commodity_price__cheap_source = [1.0 for t in s__t]
p__commodity_price__expensive_source = [10.0 for t in s__t]
p__flow_profile__demand = [10.0 for t in s__t]

p__reserve__demand = [5.0 for t in s__t]
p__penalty__demand = 1000.0

p__efficiency__cheap_link = 0.8
p__efficiency__expensive_link = 0.8
p__efficiency__triangle = 0.8

p__capacity__cheap_link = 1000.0
p__existing_units__cheap_link = 1.0
p__capacity__expensive_link = 1000.0
p__existing_units__expensive_link = 1.0
p__capacity__triangle = 1000.0
p__existing_units__triangle = 1.0

p__efficiency__cheap_unit = 0.4
p__capacity__cheap_unit = 10.0
p__existing_units__cheap_unit = 1.0
p__procurement_cost__cheap_unit = 2.0
p__max_reserve__cheap_unit = 2.0

p__efficiency__expensive_unit = 0.4
p__capacity__expensive_unit = 100.0
p__existing_units__expensive_unit = 1.0
p__procurement_cost__expensive_unit = 3.0
p__max_reserve__expensive_unit = 3.0

@variable(model,0<=v__slack__demand[s__t])

@variable(model,v__flow__cheap_link_in[s__t])
@variable(model,0<=v__flow__cheap_link_out[s__t]<=p__capacity__cheap_link*p__existing_units__cheap_link)
@variable(model,v__flow__expensive_link_in[s__t])
@variable(model,0<=v__flow__expensive_link_out[s__t]<=p__capacity__expensive_link*p__existing_units__expensive_link)
@variable(model,v__flow__triangle_in[s__t])
@variable(model,0<=v__flow__triangle_out[s__t]<=p__capacity__triangle*p__existing_units__triangle)

@variable(model,v__flow__cheap_source[s__t])
@variable(model,0<=v__flow__cheap_supply[s__t])
@variable(model,v__flow__expensive_source[s__t])
@variable(model,0<=v__flow__expensive_supply[s__t])

@variable(model,0<=v__flow_reserve__cheap_supply[s__t]<=p__max_reserve__cheap_unit*p__existing_units__cheap_unit)
@variable(model,0<=v__flow_reserve__expensive_supply[s__t]<=p__max_reserve__expensive_unit*p__existing_units__expensive_unit)

@objective(model,Min,sum(p__commodity_price__cheap_source[t]*v__flow__cheap_source[t]+p__commodity_price__expensive_source[t]*v__flow__expensive_source[t]+p__penalty__demand*v__slack__demand[t]+p__procurement_cost__cheap_unit*v__flow_reserve__cheap_supply[t]+p__procurement_cost__expensive_unit*v__flow_reserve__expensive_supply[t] for t in s__t))

@constraint(model,c__reserve_balance[t in s__t],p__reserve__demand[t]<=v__flow_reserve__cheap_supply[t]+v__flow_reserve__expensive_supply[t]+v__slack__demand[t])

@constraint(model,c__balance__demand[t in s__t],p__flow_profile__demand[t] == v__flow__cheap_link_out[t]+v__flow__expensive_link_out[t])

@constraint(model,c__efficiency__cheap_link[t in s__t], v__flow__cheap_link_out[t]==p__efficiency__cheap_link*v__flow__cheap_link_in[t])
@constraint(model,c__efficiency__expensive_link[t in s__t],v__flow__expensive_link_out[t]==p__efficiency__expensive_link*v__flow__expensive_link_in[t])
@constraint(model,c__efficiency__triangle[t in s__t], v__flow__triangle_out[t]==p__efficiency__triangle*v__flow__triangle_in[t])

@constraint(model,c__balance__cheap_supply[t in s__t],v__flow__cheap_supply[t]+v__flow__triangle_out[t]==v__flow__cheap_link_in[t])
@constraint(model,c__balance__expensive_supply[t in s__t],v__flow__expensive_supply[t]==v__flow__expensive_link_in[t]+v__flow__triangle_in[t])

@constraint(model,c__efficiency__cheap_unit[t in s__t],v__flow__cheap_supply[t]==p__efficiency__cheap_unit*v__flow__cheap_source[t])
@constraint(model,c__efficiency__expensive_unit[t in s__t], v__flow__expensive_supply[t]==p__efficiency__expensive_unit*v__flow__expensive_source[t])

@constraint(model,c__reserve_capacity__cheap_unit[t in s__t],v__flow__cheap_supply[t]+v__flow_reserve__cheap_supply[t]<=p__capacity__cheap_unit*p__existing_units__cheap_unit)
@constraint(model,c__reserve_capacity__expensive_unit[t in s__t],v__flow__expensive_supply[t]+v__flow_reserve__expensive_supply[t]<=p__capacity__expensive_unit*p__existing_units__expensive_unit)

JuMP.optimize!(model)

println(JuMP.termination_status(model))

println(JuMP.objective_value(model))

println(JuMP.value(v__flow__cheap_supply))

println(JuMP.value(v__flow__expensive_supply))

println(JuMP.value(v__slack__demand))

println(JuMP.value(v__flow_reserve__cheap_supply))

println(JuMP.value(v__flow_reserve__expensive_supply))