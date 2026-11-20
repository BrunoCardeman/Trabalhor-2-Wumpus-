
:-dynamic posicao/3.
:-dynamic memory/3.
:-dynamic visitado/2.
:-dynamic certeza/2.
:-dynamic energia/1.
:-dynamic pontuacao/1.

:-consult('mapa.pl').

delete([], _, []).
delete([Elem|Tail], Del, Result) :-
    (   \+ Elem \= Del
    ->  delete(Tail, Del, Result)
    ;   Result = [Elem|Rest],
        delete(Tail, Del, Rest)
    ).
	


reset_game :- retractall(memory(_,_,_)), 
			retractall(visitado(_,_)), 
			retractall(certeza(_,_)),
			retractall(energia(_)),
			retractall(pontuacao(_)),
			retractall(posicao(_,_,_)),
			assert(energia(100)),
			assert(pontuacao(0)),
			assert(posicao(1,1, norte)).


:-reset_game.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Controle de Status
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%atualiza pontuacao
atualiza_pontuacao(X):- pontuacao(P), retract(pontuacao(P)), NP is P + X, assert(pontuacao(NP)),!.

%atualiza energia
atualiza_energia(N):- energia(E), retract(energia(E)), NE is E + N, 
					(
					 (NE =<0, assert(energia(0)),posicao(X,Y,_),retract(posicao(_,_,_)), assert(posicao(X,Y,morto)),!);
					 (NE >100, assert(energia(100)),!);
					  (NE >0,assert(energia(NE)),!)
					 ).

%verifica situacao da nova posicao e atualiza energia e pontos
verifica_player :- posicao(X,Y,_), tile(X,Y,'P'), atualiza_energia(-100), atualiza_pontuacao(-1000),!.
verifica_player :- posicao(X,Y,_), tile(X,Y,'D'), random_between(-80,-50,D), atualiza_energia(D),!.
verifica_player :- posicao(X,Y,_), tile(X,Y,'d'), random_between(-50,-25,D), atualiza_energia(D),!.
verifica_player :- posicao(X,Y,Z), tile(X,Y,'T'), 
					map_size(SX,SY), random_between(1,SX,NX), random_between(1,SY,NY),
				retract(posicao(X,Y,Z)), assert(posicao(NX,NY,Z)), atualiza_obs, verifica_player,!.
verifica_player :- true.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Comandos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%virar direita
virar_direita :- posicao(X,Y, norte), retract(posicao(_,_,_)), assert(posicao(X, Y, leste)),atualiza_pontuacao(-1),!.
virar_direita :- posicao(X,Y, oeste), retract(posicao(_,_,_)), assert(posicao(X, Y, norte)),atualiza_pontuacao(-1),!.
virar_direita :- posicao(X,Y, sul), retract(posicao(_,_,_)), assert(posicao(X, Y, oeste)),atualiza_pontuacao(-1),!.
virar_direita :- posicao(X,Y, leste), retract(posicao(_,_,_)), assert(posicao(X, Y, sul)),atualiza_pontuacao(-1),!.

%virar esquerda
virar_esquerda :- posicao(X,Y, norte), retract(posicao(_,_,_)), assert(posicao(X, Y, oeste)),atualiza_pontuacao(-1),!.
virar_esquerda :- posicao(X,Y, oeste), retract(posicao(_,_,_)), assert(posicao(X, Y, sul)),atualiza_pontuacao(-1),!.
virar_esquerda :- posicao(X,Y, sul), retract(posicao(_,_,_)), assert(posicao(X, Y, leste)),atualiza_pontuacao(-1),!.
virar_esquerda :- posicao(X,Y, leste), retract(posicao(_,_,_)), assert(posicao(X, Y, norte)),atualiza_pontuacao(-1),!.

%andar
andar :- posicao(X,Y,P), P = norte, map_size(_,MAX_Y), Y < MAX_Y, YY is Y + 1, 
         retract(posicao(X,Y,_)), assert(posicao(X, YY, P)), 
		 %((retract(certeza(X,YY)), assert(certeza(X,YY))); assert(certeza(X,YY))),
		 set_real(X,YY),
		 ((retract(visitado(X,Y)), assert(visitado(X,Y))); assert(visitado(X,Y))),atualiza_pontuacao(-1),!.
		 
andar :- posicao(X,Y,P), P = sul,  Y > 1, YY is Y - 1, 
         retract(posicao(X,Y,_)), assert(posicao(X, YY, P)), 
		 %((retract(certeza(X,YY)), assert(certeza(X,YY))); assert(certeza(X,YY))),
		 set_real(X,YY),
		 ((retract(visitado(X,Y)), assert(visitado(X,Y))); assert(visitado(X,Y))),atualiza_pontuacao(-1),!.

andar :- posicao(X,Y,P), P = leste, map_size(MAX_X,_), X < MAX_X, XX is X + 1, 
         retract(posicao(X,Y,_)), assert(posicao(XX, Y, P)), 
		 %((retract(certeza(XX,Y)), assert(certeza(XX,Y))); assert(certeza(XX,Y))),
		 set_real(XX,Y),
		 ((retract(visitado(X,Y)), assert(visitado(X,Y))); assert(visitado(X,Y))),atualiza_pontuacao(-1),!.

andar :- posicao(X,Y,P), P = oeste,  X > 1, XX is X - 1, 
         retract(posicao(X,Y,_)), assert(posicao(XX, Y, P)), 
		 %((retract(certeza(XX,Y)), assert(certeza(XX,Y))); assert(certeza(XX,Y))),
		 set_real(XX,Y),
		 ((retract(visitado(X,Y)), assert(visitado(X,Y))); assert(visitado(X,Y))),atualiza_pontuacao(-1),!.
		 
%pegar	
pegar :- posicao(X,Y,_), tile(X,Y,'O'), retract(tile(X,Y,'O')), assert(tile(X,Y,'')), atualiza_pontuacao(-5), atualiza_pontuacao(500),set_real(X,Y),!. 
pegar :- posicao(X,Y,_), tile(X,Y,'U'), retract(tile(X,Y,'U')), assert(tile(X,Y,'')), atualiza_pontuacao(-5), atualiza_energia(50),set_real(X,Y),!. 
pegar :- atualiza_pontuacao(-5),!.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Funcoes Auxiliares de navegação e observação
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		 
%Define as 4 adjacencias		 
adjacente(X, Y) :- posicao(PX, Y, _), map_size(MAX_X,_),PX < MAX_X, X is PX + 1.  
adjacente(X, Y) :- posicao(PX, Y, _), PX > 1, X is PX - 1.  
adjacente(X, Y) :- posicao(X, PY, _), map_size(_,MAX_Y),PY < MAX_Y, Y is PY + 1.  
adjacente(X, Y) :- posicao(X, PY, _), PY > 1, Y is PY - 1.  

%cria lista com a adjacencias
adjacentes(L) :- findall(Z,(adjacente(X,Y),tile(X,Y,Z)),L).

%define observacoes locais
observacao_loc(brilho,L) :- member('O',L).
observacao_loc(reflexo,L) :- member('U',L).

%define observacoes adjacentes
observacao_adj(brisa,L) :- member('P',L).
observacao_adj(palmas,L) :- member('T',L).
observacao_adj(passos,L) :- member('D',L).
observacao_adj(passos,L) :- member('d',L).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Tratamento de KB e observações
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%consulta e processa observações
atualiza_obs:-adj_cand_obs(LP), observacoes(LO), iter_pos_list(LP,LO), observacao_certeza, observacao_vazia.

%adjacencias candidatas p/ a observacao (aquelas não visitadas)
adj_cand_obs(L) :- findall((X,Y), (adjacente(X, Y), \+visitado(X,Y)), L).

%cria lista de observacoes
observacoes(X) :- adjacentes(L), findall(Y, observacao_adj(Y,L), X).

%itera posicoes da lista para adicionar observacoes
iter_pos_list([], _) :- !.
iter_pos_list([H|T], LO) :- H=(X,Y), 
							((corrige_observacoes_antigas(X, Y, LO),!);
							adiciona_observacoes(X, Y, LO)),
							iter_pos_list(T, LO).							 

%Corrige observacoes antigas na memoria que ficaram com apenas uma adjacencia
corrige_observacoes_antigas(X, Y, []):- \+certeza(X,Y), memory(X,Y,[]).
corrige_observacoes_antigas(X, Y, LO):-
	\+certeza(X,Y), \+ memory(X,Y,[]), memory(X, Y, LM), intersection(LO, LM, L), 
	retract(memory(X, Y, LM)), assert(memory(X, Y, L)).

%Adiciona observacoes na memoria
adiciona_observacoes(X, Y, _) :- certeza(X,Y),!.
adiciona_observacoes(X, Y, LO) :- \+certeza(X,Y), \+ memory(X,Y,_), assert(memory(X, Y, LO)).

%Quando há apenas uma observação e uma unica posição incerta, deduz que a observação está na casa incerta
%e marca como certeza
%observacao_certeza:- findall((X,Y), (adjacente(X, Y), 
%						((\+visitado(X,Y), \+certeza(X,Y));(certeza(X,Y),memory(X,Y,ZZ),ZZ\=[])),
%						memory(X,Y,Z), Z\=[]), L), ((length(L,1),L=[(XX,YY)], assert(certeza(XX,YY)),!);true).
						
observacao_certeza:- observacao_certeza('brisa'),
						observacao_certeza('palmas'),
						observacao_certeza('passos').
						
observacao_certeza(Z):- findall((X,Y), (adjacente(X, Y), 
						((\+visitado(X,Y), \+certeza(X,Y));(certeza(X,Y),memory(X,Y,[Z]))),
						memory(X,Y,[Z])), L), ((length(L,1),L=[(XX,YY)], assert(certeza(XX,YY)),!);true).						

%Quando posição não tem observações
observacao_vazia:- adj_cand_obs(LP), observacao_vazia(LP).
observacao_vazia([]) :- !.
observacao_vazia([H|T]) :- H=(X,Y), ((memory(X,Y,[]), \+certeza(X,Y),assert(certeza(X,Y)),!);true), observacao_vazia(T).

%Quando posicao é visitada, atualiza memoria de posicao com a informação real do mapa 
set_real(X,Y):- ((retract(certeza(X,Y)), assert(certeza(X,Y)),!); assert(certeza(X,Y))), set_real2(X,Y),!.
set_real2(X,Y):- tile(X,Y,'P'), ((retract(memory(X,Y,_)),assert(memory(X,Y,[brisa])),!);assert(memory(X,Y,[brisa]))),!.
set_real2(X,Y):- tile(X,Y,'O'), ((retract(memory(X,Y,_)),assert(memory(X,Y,[brilho])),!);assert(memory(X,Y,[brilho]))),!.
set_real2(X,Y):- tile(X,Y,'T'), ((retract(memory(X,Y,_)),assert(memory(X,Y,[palmas])),!);assert(memory(X,Y,[palmas]))),!.
set_real2(X,Y):- ((tile(X,Y,'D'),!); tile(X,Y,'d')), ((retract(memory(X,Y,_)),assert(memory(X,Y,[passos])),!);assert(memory(X,Y,[passos]))),!.
set_real2(X,Y):- tile(X,Y,'U'), ((retract(memory(X,Y,_)),assert(memory(X,Y,[reflexo])),!);assert(memory(X,Y,[reflexo]))),!.
set_real2(X,Y):- tile(X,Y,''), ((retract(memory(X,Y,_)),assert(memory(X,Y,[])),!);assert(memory(X,Y,[]))),!.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Mostra mapa real
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
show_player(X,Y) :- posicao(X,Y, norte), write('^'),!.
show_player(X,Y) :- posicao(X,Y, oeste), write('<'),!.
show_player(X,Y) :- posicao(X,Y, leste), write('>'),!.
show_player(X,Y) :- posicao(X,Y, sul), write('v'),!.
show_player(X,Y) :- posicao(X,Y, morto), write('+'),!.

%show_position(X,Y) :- show_player(X,Y),!.
show_position(X,Y) :- (show_player(X,Y); write(' ')), tile(X,Y,Z), ((Z='', write(' '));write(Z)),!.

show_map :- map_size(_,MAX_Y), show_map(1,MAX_Y),!.
show_map(X,Y) :- Y >= 1, map_size(MAX_X,_), X =< MAX_X, show_position(X,Y), write(' | '), XX is X + 1, show_map(XX, Y),!.
show_map(X,Y) :- Y >= 1, map_size(X,_),YY is Y - 1, write(Y), nl, show_map(1, YY),!.
show_map(_,0) :- energia(E), pontuacao(P), write('E: '), write(E), write('   P: '), write(P),!.



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Mostra mapa conhecido
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

show_mem_info(X,Y) :- memory(X,Y,Z), 
		((visitado(X,Y), write('.'),!); (\+certeza(X,Y), write('?'),!); (certeza(X,Y), write('!'))),
		((member(brisa, Z), write('P'));write(' ')),
		((member(palmas, Z), write('T'));write(' ')),
		((member(brilho, Z), write('O'));write(' ')),
		((member(passos, Z), write('D'));write(' ')),
		((member(reflexo, Z), write('U'));write(' ')),!.

show_mem_info(X,Y) :- \+memory(X,Y,[]), 
			((visitado(X,Y), write('.'),!); (\+certeza(X,Y), write('?'),!); (certeza(X,Y), write('!'))),
			write('     '),!.		
		
		

show_mem_position(X,Y) :- posicao(X,Y,_), 
		((visitado(X,Y), write('.'),!); (certeza(X,Y), write('!'),!); write(' ')),
		write(' '), show_player(X,Y),
		((memory(X,Y,Z),
		((member(brilho, Z), write('O'));write(' ')),
		((member(passos, Z), write('D'));write(' ')),
		((member(reflexo, Z), write('U'));write(' ')),!);
		(write('   '),!)).

		
show_mem_position(X,Y) :- show_mem_info(X,Y),!.


show_mem :- map_size(_,MAX_Y), show_mem(1,MAX_Y),!.
show_mem(X,Y) :- Y >= 1, map_size(MAX_X,_), X =< MAX_X, show_mem_position(X,Y), write('|'), XX is X + 1, show_mem(XX, Y),!.
show_mem(X,Y) :- Y >= 1, map_size(X,_),YY is Y - 1, write(Y), nl, show_mem(1, YY),!.
show_mem(_,0) :- energia(E), pontuacao(P), write('E: '), write(E), write('   P: '), write(P),!.



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%apagar esta linha - apenas para demonstracao aleatoria
%executa_acao(X) :- L=['virar_esquerda','virar_direita','andar','pegar'],random_between(1,4,I), nth1(I, L, X),!.

%apagar linhas abaixo... sao exemplos de resposta
%executa_acao(andar) :- posicao(PX, _, oeste), PX > 1, X = andar,!.
%executa_acao(andar) :- posicao(PX, _, leste), PX < 3, X = andar,!.
%executa_acao(pegar) :- posicao(PX, PY,_), tem_ouro(PX, PY), !.
%executa_acao(voltar) :- peguei_todos_ouros,!.

%executa_acao(pegar) :- posicao(X, Y, _), memory(X, Y, Lista), member(brilho, Lista).
%executa_acao(pegar) :- posicao(X, Y, _), memory(X, Y, Lista), member(reflexo, Lista), energia(E), E < 100.
%executa_acao(andar) :- posicao(X, Y, Dir), memory(X, Y, Lista), \+ tem_perigo(Lista), \+ olhando_para_parede(X, Y, Dir), casa_frente(X, Y, Dir, Fx, Fy), \+ visitado(Fx, Fy).
%executa_acao(andar) :- posicao(X, Y, Dir), memory(X, Y, Lista), \+ tem_perigo(Lista), \+ olhando_para_parede(X, Y, Dir), casa_frente(X, Y, Dir, Fx, Fy), visitado(Fx, Fy).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% LOGICA DO AGENTE
%% executa_acao/1 chamado pelo Python.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Anota no mapa em todas as adjacencias se tem brisa, palmas ou passos

casa_frente(X, Y, norte, X, FY) :- FY is Y + 1.
casa_frente(X, Y, sul, X, FY) :- FY is Y - 1.
casa_frente(X, Y, leste, FX, Y) :- FX is X + 1.
casa_frente(X, Y, oeste, FX, Y) :- FX is X - 1.

% Antes o tamanho 12 era fixo; agora usa map_size/2
olhando_para_parede(X, Y, Dir) :- casa_frente(X, Y, Dir, Fx, Fy), \+ dentro(Fx, Fy).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  Geometria 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dentro(X, Y) :- map_size(MX, MY), X >= 1, X =< MX, Y >= 1, Y =< MY.

vizinho(X, Y, X2, Y) :- X2 is X + 1, dentro(X2, Y).
vizinho(X, Y, X2, Y) :- X2 is X - 1, dentro(X2, Y).
vizinho(X, Y, X, Y2) :- Y2 is Y + 1, dentro(X, Y2).
vizinho(X, Y, X, Y2) :- Y2 is Y - 1, dentro(X, Y2).

dir_direita(norte, leste).
dir_direita(leste, sul).
dir_direita(sul, oeste).
dir_direita(oeste, norte).
dir_esquerda(D2, D) :- dir_direita(D, D2).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  Base de conhecimento do agente 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- dynamic obs/3, inimigo_em/3, teleporte_em/2, reflexo_em/2, ultimo/4,
           energia_ant/1, fim_de_jogo/0, n_acoes/1, n_ouro/1.

reset_agente :- retractall(obs(_,_,_)), retractall(inimigo_em(_,_,_)),
    retractall(teleporte_em(_,_)), retractall(reflexo_em(_,_)),
    retractall(ultimo(_,_,_,_)), retractall(energia_ant(_)),
    retractall(fim_de_jogo), retractall(n_acoes(_)), retractall(n_ouro(_)),
    assertz(n_acoes(0)), assertz(n_ouro(0)).
:- reset_agente.

% Conhecimento do enunciado: o mapa tem 3 ouros e o maior dano de um inimigo e 80
total_ouros(3).
dano_maximo(80).

% Cada tipo de perigo e o sensor que ele dispara nas casas vizinhas
sensor(poco, brisa).
sensor(inimigo, passos).
sensor(teleporte, palmas).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  Sensores  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

sentir(L) :- observacoes(L).
percepcao_local(L) :- posicao(X, Y, _), tile(X, Y, Z), findall(P, observacao_loc(P, [Z]), L).
local(P) :- percepcao_local(L), memberchk(P, L).

% Guarda o que foi sentido na casa e lembra onde viu um item de energia (reflexo)
perceber :- posicao(X, Y, _),
    ( obs(X, Y, _) -> true ; sentir(L), assertz(obs(X, Y, L)) ),
    ( local(reflexo), \+ reflexo_em(X, Y) -> assertz(reflexo_em(X, Y)) ; true ).

% Perdeu energia sem ter um inimigo conhecido aqui -> existe um inimigo nesta casa
detecta_dano :- posicao(X, Y, _), energia(E),
    ( energia_ant(EA), E < EA, \+ inimigo_em(X, Y, _) ->
        Dano is EA - E, ( Dano < 50 -> Max = 50 ; Max = 80 ),
        assertz(inimigo_em(X, Y, Max))
    ; true ),
    retractall(energia_ant(_)), assertz(energia_ant(E)).

% Andou para (FX,FY) mas "acordou" em outro lugar -> (FX,FY) e um teletransportador
detecta_teleporte :-
    ( ultimo(X, Y, D, andar), casa_frente(X, Y, D, FX, FY), dentro(FX, FY),
      posicao(PX, PY, _), PX-PY \== FX-FY, \+ teleporte_em(FX, FY)
    -> assertz(teleporte_em(FX, FY))
    ;  true ).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  Inferencia 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
conhecida(X, Y) :- obs(X, Y, _).

% casas que o agente ja sabe que deve evitar
bloqueada(X, Y) :- inimigo_em(X, Y, _), !.
bloqueada(X, Y) :- teleporte_em(X, Y).

perigo_conhecido(inimigo, X, Y)   :- inimigo_em(X, Y, _).
perigo_conhecido(teleporte, X, Y) :- teleporte_em(X, Y).

% (X,Y) com certeza NAO tem o perigo que causa o sensor S
% se alguma vizinha visitada NAO sentiu S
sem(S, X, Y) :- vizinho(X, Y, A, B), obs(A, B, L), \+ memberchk(S, L), !.

% (X,Y) pode ser a causa do sensor do perigo H
candidato(H, X, Y) :- perigo_conhecido(H, X, Y), !.
candidato(H, X, Y) :- sensor(H, S), \+ conhecida(X, Y), \+ bloqueada(X, Y), \+ sem(S, X, Y).

% Perigo H CERTO em (X,Y): ja foi descoberto, ou uma vizinha sentiu o sensor
% de H e (X,Y) e a UNICA candidata (generaliza o antigo poco_certo)
certo(H, X, Y) :- perigo_conhecido(H, X, Y), !.
certo(H, X, Y) :- sensor(H, S), vizinho(X, Y, A, B), obs(A, B, L), memberchk(S, L),
    findall(C-D, (vizinho(A, B, C, D), candidato(H, C, D)), [X-Y]), !.

% o sensor de H sentido em (A,B) ja e explicado por um perigo certo
explicada(H, A, B) :- vizinho(A, B, C, D), certo(H, C, D), !.

% risco = quantos sensores de H "nao explicados" apontam para (X,Y)
risco(H, X, Y, R) :- sensor(H, S), aggregate_all(count,
    (vizinho(X, Y, A, B), obs(A, B, L), memberchk(S, L), \+ explicada(H, A, B)), R).

segura(X, Y) :- conhecida(X, Y), !, \+ bloqueada(X, Y).
segura(X, Y) :- sem(brisa, X, Y), sem(palmas, X, Y), sem(passos, X, Y).

% nenhum perigo certo na casa
livre(X, Y) :- \+ certo(poco, X, Y), \+ certo(inimigo, X, Y), \+ certo(teleporte, X, Y).

% casas ainda nao visitadas, vizinhas de uma visitada
fronteira(X, Y) :- map_size(MX, MY), between(1, MX, X), between(1, MY, Y),
    \+ conhecida(X, Y), \+ bloqueada(X, Y),
    once((vizinho(X, Y, A, B), conhecida(A, B))).

% energia suficiente para sobreviver ao pior inimigo
aguenta_inimigo :- energia(E), dano_maximo(M), E > M.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  Escolha de alvos (do mais seguro ao mais arriscado)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% fica so com os alvos de menor risco
menores(Ps, L) :- Ps \== [], keysort(Ps, [Min-_|_]), findall(P, member(Min-P, Ps), L).

% 1) sem nenhum perigo possivel
alvos_seguros(L) :- findall(X-Y, (fronteira(X, Y), segura(X, Y)), L), L \== [].

% 2) talvez poco (no maximo 1 brisa nao explicada), sem inimigo/teleporte possivel
alvos_poco(L) :-
    findall(R-(X-Y), (fronteira(X, Y), livre(X, Y),
                      risco(inimigo, X, Y, 0), risco(teleporte, X, Y, 0),
                      risco(poco, X, Y, R), R =< 1), Ps),
    menores(Ps, L).

% 3) talvez inimigo: so custa energia (nao pontos), entao vale arriscar se aguentar o dano
alvos_inimigo(L) :-
    findall(R-(X-Y), (fronteira(X, Y), livre(X, Y),
                      risco(poco, X, Y, 0), risco(teleporte, X, Y, 0),
                      risco(inimigo, X, Y, R)), Ps),
    menores(Ps, L).

% 4) talvez teletransporte: leva para um lugar aleatorio (ultimo recurso)
alvos_teleporte(L) :-
    findall(R-(X-Y), (fronteira(X, Y), livre(X, Y), risco(poco, X, Y, 0),
                      ( aguenta_inimigo -> true ; risco(inimigo, X, Y, 0) ),
                      risco(teleporte, X, Y, R)), Ps),
    menores(Ps, L).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  Planejamento (BFS so pelo mapa conhecido)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

caminho(Alvos, Caminho) :- posicao(X, Y, _),
    bfs([[X-Y]], [X-Y], Alvos, Rev), reverse(Rev, Caminho).

bfs([[P|Ps]|_], _, Alvos, [P|Ps]) :- memberchk(P, Alvos), !.
bfs([[X-Y|Ps]|Fila], Vis, Alvos, Cam) :-
    findall([NX-NY, X-Y|Ps],
        ( vizinho(X, Y, NX, NY), \+ memberchk(NX-NY, Vis),
          ( memberchk(NX-NY, Alvos) -> true ; passavel(NX, NY) ) ), Novos),
    findall(N, member([N|_], Novos), Ns), append(Vis, Ns, Vis2),
    append(Fila, Novos, Fila2), bfs(Fila2, Vis2, Alvos, Cam).

passavel(X, Y) :- conhecida(X, Y), \+ bloqueada(X, Y).

primeiro_passo([_, NX-NY|_], Acao) :- posicao(X, Y, D),
    casa_frente(X, Y, ND, NX, NY), !, virar_para(D, ND, Acao).

virar_para(D, D, andar) :- !.
virar_para(D, ND, virar_direita) :- dir_direita(D, ND), !.
virar_para(D, ND, virar_esquerda) :- dir_esquerda(D, ND), !.
virar_para(_, _, virar_direita).          % casa atras: vira duas vezes

ir_para(Alvos, Acao) :- caminho(Alvos, C), primeiro_passo(C, Acao).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  Decisao
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

pegou_todos :- total_ouros(T), n_ouro(T).

decide(pegar) :- local(brilho), !.
decide(pegar) :- local(reflexo), energia(E), E =< 50, !.
% ja tem os 3 ouros: volta para a origem e encerra
decide(sair)  :- pegou_todos, posicao(1, 1, _), !.
decide(A)     :- pegou_todos, ir_para([1-1], A), !.
% exploracao, do menor para o maior risco
decide(A)     :- alvos_seguros(L), ir_para(L, A), !.
decide(A)     :- alvos_poco(L), ir_para(L, A), !.
decide(A)     :- alvos_inimigo(L), aguenta_inimigo, ir_para(L, A), !.
% energia baixa para arriscar um inimigo: recarrega num item de energia conhecido
decide(pegar) :- alvos_inimigo(_), \+ aguenta_inimigo, local(reflexo), !.
decide(A)     :- alvos_inimigo(_), \+ aguenta_inimigo,
                 findall(X-Y, reflexo_em(X, Y), Us), Us \== [], ir_para(Us, A), !.
decide(A)     :- alvos_teleporte(L), ir_para(L, A), !.
decide(A)     :- posicao(X, Y, _), X-Y \== 1-1, ir_para([1-1], A), !.
decide(sair).

conta(A) :-
    ( A == pegar, local(brilho) ->
        retract(n_ouro(O)), O1 is O+1, assertz(n_ouro(O1)) ; true ),
    ( A == pegar, local(reflexo), posicao(X, Y, _) ->
        retractall(reflexo_em(X, Y)) ; true ),
    retract(n_acoes(N)), N1 is N+1, assertz(n_acoes(N1)).

sair :- ( fim_de_jogo -> true ; assertz(fim_de_jogo), relatorio ).
relatorio :- pontuacao(P), energia(E), n_ouro(O), n_acoes(N),
    format("FIM | pontuacao=~w ouro=~w energia=~w acoes=~w~n", [P, O, E, N]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  Ciclo percepcao -> decisao -> acao (chamado pelo Python)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

executa_acao(sair) :- fim_de_jogo, !.
executa_acao(A) :- posicao(X, Y, D), D \== morto,
    detecta_teleporte, detecta_dano, perceber, decide(A), conta(A),
    retractall(ultimo(_,_,_,_)), assertz(ultimo(X, Y, D, A)), !.
executa_acao(sair).
