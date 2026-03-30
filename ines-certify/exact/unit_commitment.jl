import JuMP
using JuMP:@variable, @objective, @constraint
import HiGHS

model = JuMP.Model(HiGHS.Optimizer)

s__t = [t for t in 1:10]

p__flow_profile__demand = [30.0*(1+sin(t)) for t in s__t]

p__commodity_price__cheap_source = [1.0 for t in s__t]
p__commodity_price__expensive_source = [10.0 for t in s__t]

p__efficiency__cheap_link = 1.0
p__capacity__cheap_link = 100.0
p__existing_units__cheap_link = 1.0

p__efficiency__expensive_link = 1.0
p__capacity__expensive_link = 100.0
p__existing_units__expensive_link = 1.0

p__efficiency__triangle = 1.0
p__capacity__triangle = 100.0
p__existing_units__triangle = 1.0

p__efficiency__cheap_unit = 0.4
p__efficiency_min__cheap_unit = 0.2
p__capacity__cheap_unit = 50.0
p__capacity_min__cheap_unit = 20.0
p__existing_units__cheap_unit = 1.0
p__startup_cost__cheap_unit = 100.0
p__mut__cheap_unit = 2
p__mdt__cheap_unit = 1

p__efficiency__expensive_unit = 0.4
p__efficiency_min__expensive_unit = 0.2
p__capacity__expensive_unit = 60.0
p__capacity_min__expensive_unit = 0.0
p__existing_units__expensive_unit = 1.0
p__startup_cost__expensive_unit = 10.0
p__mut__expensive_unit = 1
p__mdt__expensive_unit = 1


@variable(model,0<=v__flow__cheap_link_in[s__t])
@variable(model,0<=v__flow__cheap_link_out[s__t]<=p__capacity__cheap_link*p__existing_units__cheap_link)
@variable(model,0<=v__flow__expensive_link_in[s__t])
@variable(model,0<=v__flow__expensive_link_out[s__t]<=p__capacity__expensive_link*p__existing_units__expensive_link)
@variable(model,0<=v__flow__triangle_in[s__t])
@variable(model,0<=v__flow__triangle_out[s__t]<=p__capacity__triangle*p__existing_units__triangle)
@variable(model,0<=v__flow__cheap_source[s__t])
@variable(model,v__flow__cheap_supply[s__t])
@variable(model,0<=v__flow__expensive_source[s__t])
@variable(model,v__flow__expensive_supply[s__t])
@variable(model,v__on__cheap_unit[s__t],Bin)
@variable(model,v__on_up__cheap_unit[s__t],Bin)
@variable(model,v__on_down__cheap_unit[s__t],Bin)
@variable(model,v__on__expensive_unit[s__t],Bin)
@variable(model,v__on_up__expensive_unit[s__t],Bin)
@variable(model,v__on_down__expensive_unit[s__t],Bin)

@objective(model,Min,sum(p__startup_cost__cheap_unit*v__on_up__cheap_unit[t]+p__commodity_price__cheap_source[t]*v__flow__cheap_source[t]+p__startup_cost__expensive_unit*v__on_up__expensive_unit[t]+p__commodity_price__expensive_source[t]*v__flow__expensive_source[t] for t in s__t))

@constraint(model,c__balance__demand[t in s__t],p__flow_profile__demand[t] == v__flow__cheap_link_out[t]+v__flow__expensive_link_out[t])

@constraint(model,c__efficiency__cheap_link[t in s__t], v__flow__cheap_link_out[t]==p__efficiency__cheap_link*v__flow__cheap_link_in[t])
@constraint(model,c__efficiency__expensive_link[t in s__t],v__flow__expensive_link_out[t]==p__efficiency__expensive_link*v__flow__expensive_link_in[t])
@constraint(model,c__efficiency__triangle[t in s__t], v__flow__triangle_out[t]==p__efficiency__triangle*v__flow__triangle_in[t])

@constraint(model,c__balance__cheap_supply[t in s__t],v__flow__cheap_supply[t]+v__flow__triangle_out[t]==v__flow__cheap_link_in[t])
@constraint(model,c__balance__expensive_supply[t in s__t],v__flow__expensive_supply[t]==v__flow__expensive_link_in[t]+v__flow__triangle_in[t])

@constraint(model,c__efficiency__cheap_unit[t in s__t],v__flow__cheap_supply[t]==p__efficiency__cheap_unit*v__flow__cheap_source[t]+(1-p__efficiency__cheap_unit/p__efficiency_min__cheap_unit)*p__existing_units__cheap_unit*p__capacity_min__cheap_unit*v__on__cheap_unit[t])
@constraint(model,c__efficiency__expensive_unit[t in s__t], v__flow__expensive_supply[t]==p__efficiency__expensive_unit*v__flow__expensive_source[t]+(1-p__efficiency__expensive_unit/p__efficiency_min__expensive_unit)*p__existing_units__expensive_unit*p__capacity_min__expensive_unit*v__on__expensive_unit[t])

@constraint(model,c__on__cheap_unit[t in s__t[2:end]],v__on__cheap_unit[t]==v__on__cheap_unit[t-1]+v__on_up__cheap_unit[t]-v__on_down__cheap_unit[t])
@constraint(model,c__on_up__cheap_unit[t in s__t[p__mdt__cheap_unit:end]],v__on_up__cheap_unit[t]<=1-v__on__cheap_unit[t]-sum(v__on_down__cheap_unit[t-tk] for tk in 1:p__mdt__cheap_unit-1))
@constraint(model,c__on_down__cheap_unit[t in s__t[p__mut__cheap_unit:end]],v__on_down__cheap_unit[t]<=v__on__cheap_unit[t]-sum(v__on_up__cheap_unit[t-tk] for tk in 1:p__mut__cheap_unit-1))

@constraint(model,c__on__expensive_unit[t in s__t[2:end]],v__on__expensive_unit[t]==v__on__expensive_unit[t-1]+v__on_up__expensive_unit[t]-v__on_down__expensive_unit[t])
@constraint(model,c__on_up__expensive_unit[t in s__t[p__mdt__expensive_unit:end]],v__on_up__expensive_unit[t]<=1-v__on__expensive_unit[t]-sum(v__on_down__expensive_unit[t-tk] for tk in 1:p__mdt__expensive_unit-1))
@constraint(model,c__on_down__expensive_unit[t in s__t[p__mut__expensive_unit:end]],v__on_down__expensive_unit[t]<=v__on__expensive_unit[t]-sum(v__on_up__expensive_unit[t-tk] for tk in 1:p__mut__expensive_unit-1))

@constraint(model,c__capacity_min__cheap_unit[t in s__t],p__capacity_min__cheap_unit*p__existing_units__cheap_unit*v__on__cheap_unit[t]<=v__flow__cheap_supply[t])
@constraint(model,c__capacity_max__cheap_unit[t in s__t],v__flow__cheap_supply[t]<=p__capacity__cheap_unit*p__existing_units__cheap_unit*v__on__cheap_unit[t])

@constraint(model,c__capacity_min__expensive_unit[t in s__t],p__capacity_min__expensive_unit*p__existing_units__expensive_unit*v__on__expensive_unit[t]<=v__flow__expensive_supply[t])
@constraint(model,c__capacity_max__expensive_unit[t in s__t],v__flow__expensive_supply[t]<=p__capacity__expensive_unit*p__existing_units__expensive_unit*v__on__expensive_unit[t])

JuMP.optimize!(model)

println(JuMP.termination_status(model))

println(JuMP.objective_value(model))

println(JuMP.value(v__flow__cheap_source))

println(JuMP.value(v__flow__cheap_supply))

println(JuMP.value(v__on__cheap_unit))

println(JuMP.value(v__flow__expensive_source))

println(JuMP.value(v__flow__expensive_supply))

println(JuMP.value(v__on__expensive_unit))