import JuMP
using JuMP:@variable, @objective, @constraint
import HiGHS

model = JuMP.Model(HiGHS.Optimizer)

s__t = 1:10
s__t_cheap = 1:2:10
s__t_in_cheap = Dict(t=>[t,t+1] for t in s__t_cheap)

dt__cheap = 2

p__commodity_price__cheap_source = Dict(t=>1.0 for t in s__t_cheap)
p__commodity_price__expensive_source = [10.0 for t in s__t]
p__flow_profile__demand = [round(20.0*(sin(pi/2*t)+1)/2;digits=2) for t in s__t]#[10.0 for t in s__t]
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

@variable(model,0<=v__flow__cheap_link_in[s__t])
@variable(model,0<=v__flow__cheap_link_out[s__t]<=p__capacity__cheap_link*p__existing_units__cheap_link)
@variable(model,0<=v__flow__expensive_link_in[s__t])
@variable(model,0<=v__flow__expensive_link_out[s__t]<=p__capacity__expensive_link*p__existing_units__expensive_link)
@variable(model,0<=v__flow__triangle_in[s__t])
@variable(model,0<=v__flow__triangle_out[s__t]<=p__capacity__triangle*p__existing_units__triangle)
@variable(model,0<=v__flow__cheap_source[s__t_cheap]<=p__capacity__cheap_unit*p__existing_units__cheap_unit/p__efficiency__cheap_unit)#s__t_cheap
@variable(model,0<=v__flow__cheap_supply[s__t]<=p__capacity__cheap_unit*p__existing_units__cheap_unit)
@variable(model,0<=v__flow__expensive_source[s__t])
@variable(model,0<=v__flow__expensive_supply[s__t]<=p__capacity__expensive_unit*p__existing_units__expensive_unit)

@objective(model,Min,sum(p__commodity_price__cheap_source[t_cheap]*v__flow__cheap_source[t_cheap]*dt__cheap for t_cheap in s__t_cheap)+sum(p__commodity_price__expensive_source[t]*v__flow__expensive_source[t] for t in s__t))

@constraint(model,c__balance__demand[t in s__t],p__flow_profile__demand[t] == v__flow__cheap_link_out[t]+v__flow__expensive_link_out[t])

@constraint(model,c__efficiency__cheap_link[t in s__t], v__flow__cheap_link_out[t]==p__efficiency__cheap_link*v__flow__cheap_link_in[t])

@constraint(model,c__efficiency__expensive_link[t in s__t],v__flow__expensive_link_out[t]==p__efficiency__expensive_link*v__flow__expensive_link_in[t])

@constraint(model,c__efficiency__triangle[t in s__t], v__flow__triangle_out[t]==p__efficiency__triangle*v__flow__triangle_in[t])

@constraint(model,c__balance__cheap_supply[t in s__t],v__flow__cheap_supply[t]+v__flow__triangle_out[t]==v__flow__cheap_link_in[t])

@constraint(model,c__balance__expensive_supply[t in s__t],v__flow__expensive_supply[t]==v__flow__expensive_link_in[t]+v__flow__triangle_in[t])

@constraint(model,c__efficiency__cheap_unit[t in s__t_cheap],sum(v__flow__cheap_supply[t_in_cheap] for t_in_cheap in s__t_in_cheap[t])==dt__cheap*p__efficiency__cheap_unit*v__flow__cheap_source[t])

@constraint(model,c__efficiency__expensive_unit[t in s__t], v__flow__expensive_supply[t]==p__efficiency__expensive_unit*v__flow__expensive_source[t])

JuMP.optimize!(model)

println(JuMP.termination_status(model))

println(JuMP.objective_value(model))

println(JuMP.value(v__flow__cheap_source))

println(JuMP.value(v__flow__expensive_source))