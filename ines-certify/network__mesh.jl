import JuMP
using JuMP:@variable, @objective, @constraint
import HiGHS

model = JuMP.Model(HiGHS.Optimizer)

p__commodity_price__cheap_source = 1.0
p__commodity_price__expensive_source = 10.0
p__flow_profile__demand = 10.0
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
p__capacity__cheap_unit = 100.0
p__existing_units__cheap_unit = 1.0
p__capacity__expensive_unit = 100.0
p__existing_units__expensive_unit = 1.0

@variable(model,0<=v__flow__cheap_link_in)
@variable(model,0<=v__flow__cheap_link_out<=p__capacity__cheap_link*p__existing_units__cheap_link)
@variable(model,0<=v__flow__expensive_link_in)
@variable(model,0<=v__flow__expensive_link_out<=p__capacity__expensive_link*p__existing_units__expensive_link)
@variable(model,0<=v__flow__triangle_in)
@variable(model,0<=v__flow__triangle_out<=p__capacity__triangle*p__existing_units__triangle)
@variable(model,0<=v__flow__cheap_source)
@variable(model,0<=v__flow__cheap_supply<=p__capacity__cheap_unit*p__existing_units__cheap_unit)
@variable(model,0<=v__flow__expensive_source)
@variable(model,0<=v__flow__expensive_supply<=p__capacity__expensive_unit*p__existing_units__expensive_unit)

@objective(model,Min,p__commodity_price__cheap_source*v__flow__cheap_source+p__commodity_price__expensive_source*v__flow__expensive_source)

@constraint(model,c__balance__demand,p__flow_profile__demand == v__flow__cheap_link_out+v__flow__expensive_link_out)

@constraint(model,c__efficiency__cheap_link, v__flow__cheap_link_out==p__efficiency__cheap_link*v__flow__cheap_link_in)

@constraint(model,c__efficiency__expensive_link,v__flow__expensive_link_out==p__efficiency__expensive_link*v__flow__expensive_link_in)

@constraint(model,c__efficiency__triangle, v__flow__triangle_out==p__efficiency__triangle*v__flow__triangle_in)

@constraint(model,c__balance__cheap_supply,v__flow__cheap_supply+v__flow__triangle_out==v__flow__cheap_link_in)

@constraint(model,c__balance__expensive_supply,v__flow__expensive_supply==v__flow__expensive_link_in+v__flow__triangle_in)

@constraint(model,c__efficiency__cheap_unit,v__flow__cheap_supply==p__efficiency__cheap_unit*v__flow__cheap_source)

@constraint(model,c__efficiency__expensive_unit, v__flow__expensive_supply==p__efficiency__expensive_unit*v__flow__expensive_source)

JuMP.optimize!(model)

println(JuMP.termination_status(model))

println(JuMP.objective_value(model))

println(JuMP.value(v__flow__cheap_source))

println(JuMP.value(v__flow__expensive_source))