
## Bibliotecas
using JuMP, Cbc, CSV, DataFrames
using LinearAlgebra
using Gurobi
using PlotlyJS
using Combinatorics
using TableView
using Dates
## Funcoes para gerar coordenadas
function fun_gerar_coordenadas(ary_posicoes,D_P,direcao)
    # direcao 1 no comprimento
    # direcao 2 na largura
    # direcao 3 na altura
        ## Gerar conjunto O (length)
        inicio=now() # inicio do pre-processamento
        coord_O = Int[] # Conjunto dos pontos p horizontais (length)
        # n_max onde as iteracoes devem parar,
        # o grid nao pode ser maior que isso pois a caixa nao cabe
        # n_max_H = Comprimento(L)/(Lado da Caixa(i))
        n_max_O = Vector{Int64}[]
        Max_O = D_P[direcao] - minimum(ary_posicoes[:,direcao+1])
        # Cria um n_max_O para cada caixa
        for n_i in 1:length(ary_posicoes[:,direcao+1])
            push!(n_max_O, Vector{Int64}(0:trunc(Int,Max_O/ary_posicoes[n_i,direcao+1])))
        end
        ary_comb_n=Iterators.product(n_max_O...)
        # Posicoes que as caixas odem ocupar
        # restricao para criacao do grid D_P(L) - max(d_c)
        # loop para montar o grid
        for n_i in ary_comb_n
            coord_p=sum(n_i .* ary_posicoes[:,direcao+1]) # produto vetorial
            if coord_p<=Max_O
                append!(coord_O,coord_p)
            end
        end
        fim = now()-inicio
        unique!(coord_O)
        println("Executado em ", fim)
        println("Conjunto de posições (bottom-left) que pertmitem caixas, Conj=",coord_O)
        return coord_O
end
## Funcao que retorna o numero de combinacoes para montagem do grid reduzido
function teste_combinatoria(D_P,ary_posicoes,direcao)
    coord_O = Int[]
    n_max_O = Vector{Int64}[]
    Max_O = D_P[direcao] - minimum(ary_posicoes[:,direcao+1])
    for n_i in 1:length(ary_posicoes[:,direcao])
        push!(n_max_O, Vector{Int64}(0:trunc(Int,Max_O/ary_posicoes[n_i,direcao+1])))
    end
    soma=1.0
    for vec in n_max_O
        soma=soma*length(vec)
    end
    println(soma)
    return soma
end
## Caminho para salvar resultados e dados. Manter final '.csv'
caminho = "C:/Users/mizus/OneDrive/Área de Trabalho/Palete Trabalho/Resultados/resultado_instancia.csv"
## lista de modelos para rodar
modelos = [Cbc.Optimizer,Gurobi.Optimizer]
# lista de enderecos para rodar
arquivos=["C:/Users/mizus/OneDrive/Área de Trabalho/Palete Trabalho/Trabalho Interira/InstanciasSelecionadas/ep3-20-L-C-50.csv",
"C:/Users/mizus/OneDrive/Área de Trabalho/Palete Trabalho/Trabalho Interira/InstanciasSelecionadas/ep3-20-U-C-50.csv",
"C:/Users/mizus/OneDrive/Área de Trabalho/Palete Trabalho/Trabalho Interira/InstanciasSelecionadas/ep3-20-U-C-90.csv",
"C:/Users/mizus/OneDrive/Área de Trabalho/Palete Trabalho/Trabalho Interira/InstanciasSelecionadas/ep3-20-U-R-90.csv",
"C:/Users/mizus/OneDrive/Área de Trabalho/Palete Trabalho/Trabalho Interira/InstanciasSelecionadas/ep3-40-D-R-90.csv",
"C:/Users/mizus/OneDrive/Área de Trabalho/Palete Trabalho/Trabalho Interira/InstanciasSelecionadas/ep3-40-F-R-90.csv",
"C:/Users/mizus/OneDrive/Área de Trabalho/Palete Trabalho/Trabalho Interira/InstanciasSelecionadas/ep3-40-U-R-90.csv",
"C:/Users/mizus/OneDrive/Área de Trabalho/Palete Trabalho/Trabalho Interira/InstanciasSelecionadas/ep3-60-D-R-90.csv",
"C:/Users/mizus/OneDrive/Área de Trabalho/Palete Trabalho/Trabalho Interira/InstanciasSelecionadas/ep3-60-F-C-90.csv",
"C:/Users/mizus/OneDrive/Área de Trabalho/Palete Trabalho/Trabalho Interira/InstanciasSelecionadas/ep3-60-F-R-90.csv"]
## DataFrame para acompanhar tempos
vec_tempo = zeros(Int64,2)
df_tempo = DataFrame(modelo = [1],tempo_grid=[1],tempo_sobreposicao=[1])

## Loop para executar todos os arquivos e solvers
for arquivo in arquivos
    println("Iniciando arquivo")
    println(SubString(arquivos[1], 100, 112))
    # flag para fazer o grafico
    var_plot=0
    # timer de pre-preocessamento
    tempo_prepro=now()
    # Leitura de arquivos
    dados_caixas = CSV.File(arquivo, header=0)
    df_dados_caixas=DataFrame(dados_caixas) # Transforma o array em dataframe
    rename!(df_dados_caixas,["etc","index","comprimento","altura","largura","valor","quantidade"]) #renomeia colunas
    D_P=df_dados_caixas[1,["index","altura","comprimento"]] # separa as dimensoes do conteiner para calculos
    # calcula o volume de cada caixa
    ary_volume=prod.(eachrow(df_dados_caixas[!,["comprimento","altura","largura"]]))
    df_dados_caixas=hcat(df_dados_caixas,ary_volume)
    rename!(df_dados_caixas, :x1 => :volume)
    # separa os dados das caixas para os calculos
    ary_posicoes=df_dados_caixas[2:end, ["index","comprimento","largura","altura"]]

    # Gerar combinacoes de rotacao para cada caixa
    ary_posicoes=Array{Int64}(undef, 0, 4)
    ary_posicoes=df_dados_caixas[2:end, ["index","comprimento","largura","altura"]]
    ary_posicoes=df_dados_caixas[2:4, ["index","comprimento","largura","altura"]]
    ## Funcao de montagem dos pontos para o grid

    ## Gerar conjunto de pontos para o grid de todas as caixas
    num_combinatoria_p = teste_combinatoria(D_P,ary_posicoes,1)
    num_combinatoria_q = teste_combinatoria(D_P,ary_posicoes,2)
    num_combinatoria_r = teste_combinatoria(D_P,ary_posicoes,3)
    comb_max=max(num_combinatoria_p,num_combinatoria_q,num_combinatoria_r)
    if comb_max <= 1e9 # Aproximadamente 15 min para rodar o meior eixo (proporcao caixa-paete)
        # Gera grid ideal para a combinacao de todas as caixas
        println("Montando grid por combinatória.")
        coord_O=fun_gerar_coordenadas(ary_posicoes,D_P,1) # Coordenadas Comprimento
        coord_R=fun_gerar_coordenadas(ary_posicoes,D_P,2) # Coordenadas Largura
        coord_A=fun_gerar_coordenadas(ary_posicoes,D_P,3) # Coordenadas Altura
    else
        # Caso a combinatoria seja maior que e9
        # gerar um grid unitario (definido) para todas as caixas
        if length(ary_posicoes[:,1])<=20 # Ate 20 caixas
            println("Montando grid padrão combinatória, para 20 caixas ou menos.")
            coord_O = collect(0:5:D_P[1]) # Comprimento
            coord_R = collect(0:8:D_P[2]) # Largura
            coord_A = collect(0:5:D_P[3]) # Altura
        elseif length(ary_posicoes[:,1])<=40 # Ate 40 caixas
            println("Montando grid padrão combinatória, para 40 caixas ou menos.")
            coord_O = collect(0:7:D_P[1]) # Comprimento
            coord_R = collect(0:9:D_P[2]) # Largura
            coord_A = collect(0:7:D_P[3]) # Altura
        else # mais de 40 caixas
            println("Montando grid padrão combinatória, para 60 caixas ou menos.")
            coord_O = collect(0:8:D_P[1]) # Comprimento
            coord_R = collect(0:12:D_P[2]) # Largura
            coord_A = collect(0:8:D_P[3]) # Altura
        end
    end
    # Numero de variáveis para cada quantidade de caixas
    # para o grid unitario
    17*17*21*20 # para 20 caixas
    12*12*18*40# Para 40 caixas
    11*11*14*60# Para 60 caixas
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

    #print("Conjunto de coordenadas bottom left para as caixas:")
    #display(ary_cood)
    ary_cood=hcat(ary_cood,zeros(length(ary_cood[:,1])))
    # Pontos das dimensoes maximas do pallete
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
    if var_plot==1
        plot(
            df_coords,
            x=:p, y=:q, z=:r,color=:tipo,
            type="scatter3d", mode="markers"
        )
    end
    ## Definicao da variavel Sum{C(i,p,q)}
    # (p,q, r) coordenadas
    # Montagem do conjunto de coordendas para cada tipo de caixa
    df_coord_Cpqr=Array{Any}(undef, 0, 6)
    for n_i in ary_posicoes[:,1]
        conj_p = coord_O[coord_O .<= (D_P[1]-ary_posicoes[n_i+1,2])]
        conj_q = coord_R[coord_R .<= (D_P[2]-ary_posicoes[n_i+1,3])]
        conj_r = coord_A[coord_A .<= (D_P[3]-ary_posicoes[n_i+1,4])]

        for n_p in conj_p
          for n_q in conj_q
              for n_r in conj_r
                  str_coord=string(string(n_i+1),"_",n_p,"_",n_q ,"_",n_r)
                  df_coord_Cpqr=[df_coord_Cpqr;permutedims([n_i+1,n_p,n_q,n_r,str_coord,
                  select(subset(df_dados_caixas, :index => a -> a .== n_i),:volume)[:,1][1]])]
              end
          end
        end
    end
    #println("Conjunto de pontos C(p,q,r) para cada caixa i:")
    #display(df_coord_Cpqr)
    # Fim do pre-processamento
    println("Tempo do pre-processamento:",now()-tempo_prepro)
    for modelo in modelos
        ## Funcao Objetivo
        model_1 = Model(modelo)
        # Criacao das variaveis
        @variable(model_1,x_1[df_coord_Cpqr[:,5]], binary=true)
        #Convertendo para uma vetor float para multiplicar com a variavel
        coef=Vector{Float64}(df_coord_Cpqr[:,6])
        @objective(model_1, Max, sum(coef' * x_1))
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
        #print("Conjunto de coordenadas para montagem das resticoes (s, t, u):")
        #display(ary_cood_e)
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
        end
        # Restricoes de quantidade
        for caixa in df_dados_caixas[2:end,:index]
            vec_res = zeros(Int64, length(df_coord_Cpqr[:,1])) # loop do ponto virtual
            for tipo in 1:length(x_1)
                if (caixa+1)==df_coord_Cpqr[tipo,1]
                    vec_res[tipo]=1
                else
                    vec_res[tipo]=0
                end
            end
            iter=caixa+2
            @constraint(model_1,sum(vec_res' * x_1)<= df_dados_caixas[iter,:quantidade])
        end
        ## Otimizacao
        set_time_limit_sec(model_1,10*60)#
        JuMP.optimize!(model_1)

        println("Objective value: ", JuMP.objective_value(model_1))
        println("Sumário da solução:",solution_summary(model_1, verbose=false))

        var = all_variables(model_1)
        df_resultados_1=DataFrame(
            name = var,
            Value = value.(var),
            )
        # Salva resultados
        # Salva solucao do modelo em csv
        salvar_caminho = replace(caminho,".csv" => SubString(arquivo, 100, 112)*"_.csv")
        salvar_caminho = replace(salvar_caminho,".csv" => string(modelo) *".csv")
        CSV.write(salvar_caminho,
          df_resultados_1,header=true,delim=";")
        # Salva parametros do modelo em txt
        s=solution_summary(model_1)
        salvar_caminho=replace(salvar_caminho,".csv" => ".txt")
        open(salvar_caminho,"a") do io
         println(io,"a=",s)
        end
    end
    println("Finalizando arquivo")
end
