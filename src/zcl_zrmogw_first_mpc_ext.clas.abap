CLASS zcl_zrmogw_first_mpc_ext DEFINITION
  PUBLIC
  INHERITING FROM zcl_zrmogw_first_mpc
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES: BEGIN OF ts_conexoes_deep,
             carrid                     TYPE s_carr_id,
             carrname                   TYPE  s_carrname,
             currcode                   TYPE  s_currcode,
             url                        TYPE s_carrurl,
             companhiaaereatohorariovoo TYPE TABLE OF zcl_zrmogw_first_mpc_ext=>ts_horariovoo WITH DEFAULT KEY,
           END OF ts_conexoes_deep,

           tt_conexoes_deep TYPE TABLE OF ts_conexoes_deep.
protected section.
private section.
ENDCLASS.



CLASS ZCL_ZRMOGW_FIRST_MPC_EXT IMPLEMENTATION.
ENDCLASS.
