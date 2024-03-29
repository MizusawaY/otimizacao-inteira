
## Bibliotecas ----------------------------------
using JuMP, Cbc, CSV, DataFrames
using LinearAlgebra
using Gurobi
using PlotlyJS
using Combinatorics
using TableView
#ENV["GUROBI_HOME"] = "C:/gurobi950/win64"
#Pkg.build("Gurobi") # verifica se instalacao esta ok
var_plot=1

## Definicao de variaveis

# Dimensoes do pallete -----------------------------------------------
# Width (W) - largura
# Length (L)- comprimento
# D_P = [L, W, H]
# D_P = [12,10,15] # Vetor

# Dimensoes da caixa ------------------------------------------
# d_c = [l, w, h]
# d_c = [6,4,5]
df_dados_caixas = DataFrame(CSV.File("dados_caixas_teste.csv"))

# Gerar combinacoes de rotacao para cada caixa
# Retirado desse modelo pois nao precisamos
# ary_posicoes=Array{Int64}(undef, 0, 4)
# for i in 1:factorial(length(d_c))
#     ary_posicoes=[ary_posicoes;transpose(append!([i],collect(nthperm(d_c,i))))]
# end

ary_posicoes=Array{Int64}(undef, 0, 4)
# ary_posicoes=df_dados_caixas[:,1:4]
ary_posicoes=df_dados_caixas[2:end, ["index","comprimento","largura","altura"]]

ary_posicoes=df_dados_caixas[2:6, ["index","comprimento","largura","altura"]]

display(ary_posicoes)
display(D_P)
showtable(df_dados_caixas)
showtable(ary_posicoes)

## Gerar conjunto O (length)
coord_O = Int[] # Conjunto dos pontos p horizontais (length)
# n_max onde as iteracoes devem parar,
# o grid nao pode ser maior que isso pois a caixa nao cabe
# n_max_H = Comprimento(L)/(Lado da Caixa(i))
n_max_O = Vector{Int64}[]
# Cria um n_max_O para cada caixa
for n_i in 1:length(ary_posicoes[:,1])
    push!(n_max_O, Vector{Int64}(0:trunc(Int,D_P[1]/ary_posicoes[n_i,2])))
end
println(n_max_O)
ary_comb_n=collect(Iterators.product(n_max_O...))

# Posicoes que as caixas odem ocupar
# restricao para criacao do grid D_P(L) - max(d_c)
Max_O = D_P[1] - minimum(ary_posicoes[:,2])
# loop para montar o grid
for n_i in 1:length(ary_comb_n)
    coord_p=sum(collect(ary_comb_n[n_i]) .* ary_posicoes[:,2]) # produto vetorial
    if coord_p<=Max_O
        append!(coord_O,coord_p)
    end
end
unique!(coord_O)
println("Conjunto O de posições p (bottom-left) que pertmitem caixas, O=",coord_O)

## Gerar conjunto R (width)
coord_R = Int[] # Conjunto dos pontos p horizontais (length)df_da
# n_max onde as iteracoes devem parar,
# o grid nao pode ser maior que isso pois a caixa nao cabe
# n_max_H = Comprimento(L)/(Lado da Caixa(i))
n_max_R = Vector{Int64}[]
# Cria um n_max_R para cada caixa
for n_i in 1:length(ary_posicoes[:,1])
    println(n_i)
    push!(n_max_R, Vector{Int64}(0:trunc(Int,D_P[2]/ary_posicoes[n_i,3])))
end
println(n_max_R)
ary_comb_n=collect(Iterators.product(n_max_R...))
#ar[2]
# Posicoes que as caixas odem ocupar
# restricao para criacao do grid D_P(L) - max(d_c)
Max_R = D_P[2] - minimum(ary_posicoes[:,3])
# loop para montar o grid
# Generalizar para mais caixas
for n_i in 1:length(ary_comb_n)
    coord_q=sum(collect(ary_comb_n[n_i]) .* ary_posicoes[:,3])
    if coord_q<=Max_R
        append!(coord_R,coord_q)
    end
end
unique!(coord_R)
println("Conjunto R de posições q (bottom-left) que pertmitem caixas, R = ",coord_R)
## Gerar conjunto R (width)
coord_A = Int[] # Conjunto dos pontos p horizontais (length)
# n_max onde as iteracoes devem parar,
# o grid nao pode ser maior que isso pois a caixa nao cabe
# n_max_H = Comprimento(L)/(Lado da Caixa(i))
n_max_A = Vector{Int64}[]
# Cria um n_max_R para cada caixa
for n_i in 1:length(ary_posicoes[:,1])
    println(n_i)
    push!(n_max_A, Vector{Int64}(0:trunc(Int,D_P[3]/ary_posicoes[n_i,4])))
end
println(n_max_A)
ary_comb_n=collect(Iterators.product(n_max_A...))
#ar[2]
# Posicoes que as caixas odem ocupar
# restricao para criacao do grid D_P(L) - max(d_c)
Max_A = D_P[3] - minimum(ary_posicoes[:,4])
# loop para montar o grid
# Generalizar para mais caixas
for n_i in 1:length(ary_comb_n)
    coord_r=sum(collect(ary_comb_n[n_i]) .* ary_posicoes[:,4])
    if coord_r<=Max_A
        append!(coord_A,coord_r)
    end
end
unique!(coord_A)
println("Conjunto A de posições p (bottom-left) que pertmitem caixas, A =",coord_A)

## Montagem do plot do grid
ary_cood=Array{Int64}(undef, 0, 3)
for n_i in coord_O
    for n_ii in coord_R
        # concatenate hcat & vcat
        for n_iii in coord_A
            ary_cood=[ary_cood;transpose([n_i,n_ii,n_iii])]
        end
    end
end

print("Conjunto de coordenadas bottom left para as caixas:")
display(ary_cood)

ary_cood=hcat(ary_cood,zeros(length(ary_cood[:,1])))


# Pontos ddas dimensoes maximas do pallete
ary_cood=[ary_cood;transpose([D_P[1],0,0,1])] # ultimo ponto na horizontal
ary_cood=[ary_cood;transpose([0,D_P[2],0,1])] # ultimo ponto no width
ary_cood=[ary_cood;transpose([0,0,D_P[3],1])] # ultimo ponto na vertical

ary_cood=[ary_cood;transpose([D_P[1],D_P[2],0,1])] # ultimo ponto base
ary_cood=[ary_cood;transpose([0,D_P[2],D_P[3],1])] # ultimo
ary_cood=[ary_cood;transpose([D_P[1],0,D_P[3],1])] # ultimo
ary_cood=[ary_cood;transpose([D_P[1],D_P[2],D_P[3],1])] # ultimo ponto cima

ary_cood[1,4]=2
# Plot do esquema das coordendas bpottom left
df_coords=DataFrame(ary_cood,:auto)
rename!(df_coords, ["p","q","r","tipo"])
plot(
    df_coords,
    x=:p, y=:q, z=:r,color=:tipo,
    type="scatter3d", mode="markers"
)



#CSV.write("D:/GoogleDrive/Mestrado/ICMC/Apresentações/Palete de Caixas/combinatoria[10_645]_O.csv",
# ary_comb_n,header=false,delim=";")


#CSV.write("D:/GoogleDrive/Mestrado/ICMC/Apresentações/Palete de Caixas/grid_[10_8_12_6_4_5_i3].csv",
#  ary_cood, writeheader=false,delim=";")




# Definicao da variavel Sum{C(i,p,q)}
# onde, i = caixa vertical ou horizontal
# (p,q, r) coordenadas
# Montagem do conjunto de coordendas para cada tipo de caixa

df_coord_Cpqr=Array{Any}(undef, 0, 6)
for n_i in 1:length(ary_posicoes[:,1])
    conj_p = coord_O[coord_O .<= (D_P[1]-ary_posicoes[n_i,2])]
    conj_q = coord_R[coord_R .<= (D_P[2]-ary_posicoes[n_i,3])]
    conj_r = coord_A[coord_A .<= (D_P[3]-ary_posicoes[n_i,4])]
    #println(conj_p,conj_q,conj_r)
    for n_p in conj_p
      for n_q in conj_q
          for n_r in conj_r
              str_coord=string(string(n_i),"_",n_p,"_",n_q ,"_",n_r)
              df_coord_Cpqr=[df_coord_Cpqr;permutedims([n_i,n_p,n_q,n_r,str_coord,
              select(subset(df_dados_caixas, :index => a -> a .== n_i),:volume)[:,1][1]])]
          end
      end
    end
end

println("Conjunto de pontos C(p,q,r) para cada caixa i:")
display(df_coord_Cpqr)

## FO
model_1 = Model(Cbc.Optimizer)
model_2 = Model(Gurobi.Optimizer)
model_2 = Model(Cbc.Optimizer)

# Generalizar esta parte
@variable(model_1,x_1[i=1:length(df_coord_Cpqr[:,5])], binary=true)
@variable(model_2,x_2[df_coord_Cpqr[:,5]], binary=true)
#Convertendo para uma vetor float para multiplicar com a variavel
coef=Vector{Float64}(df_coord_Cpqr[:,6])
@objective(model_1, Max, sum(x_1))
@objective(model_2, Max, sum(coef' * x_2))


print(model_1)
print(model_2)


## Restricoes
# Restricao de sobreposicao (sobreposicao e caixas no mesmo ponto)
# Montagem do  grid "e (p,q,r,s)"" virtual para comparacao
ary_cood_e=Array{Int64}(undef, 0, 3)
for n_s in coord_O
    for n_t in coord_R
        for n_u in coord_A
            ary_cood_e=[ary_cood_e;transpose([n_s,n_t,n_u])]
        end
    end
end
print("Conjunto de coordenadas para montagem das resticoes (s, t, u):")
display(ary_cood_e)

# Gera os parametros e de sobreposicao
vec_res = zeros(Int64, length(df_coord_Cpqr[:,1])) # loop do ponto virtual
for n_stu in 1:length(ary_cood_e[:,1])
    for n_pqr in 1:length(df_coord_Cpqr[:,1]) # loop das posicoes
        bl_e = false
        bl_e_p = false
        bl_e_q = false
        bl_e_r = false
        # e, para p & s
        if (df_coord_Cpqr[n_pqr,2]<=ary_cood_e[n_stu,1] && # p <= s ponto p "antes" da referencia virtual r
            ary_cood_e[n_stu,1]<=(df_coord_Cpqr[n_pqr,2]+ary_posicoes[df_coord_Cpqr[n_pqr,1],2]-1) && # s <= p + li - 1 ponto p+li "entra" na referencia virtual r
            df_coord_Cpqr[n_pqr,2]<=D_P[1]-ary_posicoes[df_coord_Cpqr[n_pqr,1],2]) # p + li - 1 <= L-1 ponto p nao pode passar do comprimento total menos comprimento da caixa
            bl_e_p=true
        end
        # e, para q & t
        if (df_coord_Cpqr[n_pqr,3]<=ary_cood_e[n_stu,2] && # q <= t ponto p "antes" da referencia virtual r
            ary_cood_e[n_stu,2]<=(df_coord_Cpqr[n_pqr,3]+ary_posicoes[df_coord_Cpqr[n_pqr,1],3]-1) && # t <= q + wi - 1 ponto p+li "entra" na referencia virtual r
            df_coord_Cpqr[n_pqr,3]<=D_P[2]-ary_posicoes[df_coord_Cpqr[n_pqr,1],3]) # q + wi - 1 <= W-1 ponto q nao pode passar do comprimento total menos comprimento da caixa
            bl_e_q=true
        end
        #e, para r & u
        if (df_coord_Cpqr[n_pqr,4]<=ary_cood_e[n_stu,3] && # r <= u ponto p "antes" da referencia virtual r
            ary_cood_e[n_stu,3]<=(df_coord_Cpqr[n_pqr,4]+ary_posicoes[df_coord_Cpqr[n_pqr,1],4]-1) && # u <= r + wi - 1 ponto p+li "entra" na referencia virtual r
            df_coord_Cpqr[n_pqr,4]<=D_P[3]-ary_posicoes[df_coord_Cpqr[n_pqr,1],4]) # r + hi - 1 <= H-1 ponto r nao pode passar do comprimento total menos comprimento da caixa
            bl_e_r=true
        end

        # e final
        bl_e = bl_e_p*bl_e_q*bl_e_r
        # println("Caixa :")
        # println(n_stu)
        if (bl_e==true)
            vec_res[n_pqr]=1
        else
            vec_res[n_pqr]=0
        end
    end
    # println(vec_res)
    # coluna 6 comecam as restricoes
    df_coord_Cpqr=hcat(df_coord_Cpqr,vec_res)
    @constraint(model_1,sum(vec_res' * x_1)<= 1)
    @constraint(model_2,sum(vec_res' * x_2)<= 1)
end
# coluna 6 comecam as restricoes
display(df_coord_Cpqr)
showtable(df_coord_Cpqr)

# Numero maximo de caixas no pallete
# Rever no cenário de  caixas diferentes
# max_c = floor(Int64,(D_P[1]*D_P[2]*D_P[3])/(d_c[1]*d_c[2]*d_c[3]))

# @constraint(model_1,sum(x_1)<= max_c)
# @constraint(model_2,sum(x_2)<= max_c)

print(model_1)
print(model_2)

# Restricoes de quantidade ---------------------

for caixa in df_dados_caixas[2:end,:index]
    vec_res = zeros(Int64, length(df_coord_Cpqr[:,1])) # loop do ponto virtual
    for tipo in 1:length(x_2)
        if caixa==df_coord_Cpqr[tipo,1]
            vec_res[tipo]=1
        else
            vec_res[tipo]=0
        end
    end
    #println(vec_res' * x_2)
    @constraint(model_1,sum(vec_res' * x_1)<= df_dados_caixas[caixa+1,:quantidade])
    @constraint(model_2,sum(vec_res' * x_2)<= df_dados_caixas[caixa+1,:quantidade])

end
# Otimizar
#JuMP.optimize!(model_1)
#println("Objective value: ", JuMP.objective_value(model_1))
#println(solution_summary(model_1, verbose=true))

set_time_limit_sec(model_2,100)
#JuMP.optimize!(model_1)
JuMP.optimize!(model_2)

println("Objective value: ", JuMP.objective_value(model_2))
println(solution_summary(model_2, verbose=true))

var = all_variables(model_2)
df_resultados=DataFrame(
    name = var,
    Value = value.(var),
    )


# Salva resultados ---------------------------------
CSV.write("C:/Users/mizus/OneDrive/Área de Trabalho/Palete Trabalho/resultado_teste_isntancia_1.csv",
  df_resultados,header=true,delim=";")
# Salva restricoes de sobreposição
#CSV.write("C:/Users/mizus/OneDrive/Área de Trabalho/Palete Trabalho/restrições_sobreposição_teste_1.csv",
#  Tables.table(df_coord_Cpqr),header=false,delim=";")
