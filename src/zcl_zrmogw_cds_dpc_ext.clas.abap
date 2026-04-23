class ZCL_ZRMOGW_CDS_DPC_EXT definition
  public
  inheriting from ZCL_ZRMOGW_CDS_DPC
  create public .

public section.

  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~CREATE_DEEP_ENTITY
    redefinition .
protected section.
private section.
ENDCLASS.



CLASS ZCL_ZRMOGW_CDS_DPC_EXT IMPLEMENTATION.


  METHOD /iwbep/if_mgw_appl_srv_runtime~create_deep_entity.

    CASE iv_entity_name.
      WHEN 'ZRMOCDS_CompanhiaAerea'.

      WHEN OTHERS.
    ENDCASE.

  ENDMETHOD.
ENDCLASS.
