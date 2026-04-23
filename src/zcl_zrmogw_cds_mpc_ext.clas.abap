CLASS zcl_zrmogw_cds_mpc_ext DEFINITION
  PUBLIC
  INHERITING FROM zcl_zrmogw_cds_mpc
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ts_conexoes_deep_entity.
        INCLUDE TYPE ts_zrmocds_companhiaaereatype.
    TYPES: to_horariovoo TYPE TABLE OF ts_zrmocds_horariovootype WITH DEFAULT KEY.
    TYPES: END OF ts_conexoes_deep_entity .

    METHODS define
        REDEFINITION .
protected section.
private section.
ENDCLASS.



CLASS ZCL_ZRMOGW_CDS_MPC_EXT IMPLEMENTATION.


  METHOD define.
    TRY.
        super->define( ).
        model->get_entity_type( iv_entity_name = 'ZRMOCDS_CompanhiaAerea' )->bind_structure( iv_structure_name = 'ZCL_ZRMOGW_CDS_MPC_EXT=>TS_CONEXOES_DEEP_ENTITY' ).
      CATCH /iwbep/cx_mgw_med_exception.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
