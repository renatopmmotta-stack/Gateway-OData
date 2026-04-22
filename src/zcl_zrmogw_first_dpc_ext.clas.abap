class ZCL_ZRMOGW_FIRST_DPC_EXT definition
  public
  inheriting from ZCL_ZRMOGW_FIRST_DPC
  create public .

public section.

  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~CREATE_DEEP_ENTITY
    redefinition .
protected section.

  methods COMPANHIAAEREASE_CREATE_ENTITY
    redefinition .
  methods COMPANHIAAEREASE_DELETE_ENTITY
    redefinition .
  methods COMPANHIAAEREASE_GET_ENTITY
    redefinition .
  methods COMPANHIAAEREASE_GET_ENTITYSET
    redefinition .
  methods COMPANHIAAEREASE_UPDATE_ENTITY
    redefinition .
  methods HORARIOVOOSET_CREATE_ENTITY
    redefinition .
  methods HORARIOVOOSET_DELETE_ENTITY
    redefinition .
  methods HORARIOVOOSET_GET_ENTITY
    redefinition .
  methods HORARIOVOOSET_GET_ENTITYSET
    redefinition .
  methods HORARIOVOOSET_UPDATE_ENTITY
    redefinition .
  methods VOOSET_CREATE_ENTITY
    redefinition .
  methods VOOSET_DELETE_ENTITY
    redefinition .
  methods VOOSET_GET_ENTITY
    redefinition .
  methods VOOSET_GET_ENTITYSET
    redefinition .
  methods VOOSET_UPDATE_ENTITY
    redefinition .
private section.

  methods CONEXOES_DEEP_ENTITY
    importing
      !IV_ENTITY_NAME type STRING optional
      !IV_ENTITY_SET_NAME type STRING optional
      !IV_SOURCE_NAME type STRING optional
      !IO_DATA_PROVIDER type ref to /IWBEP/IF_MGW_ENTRY_PROVIDER
      !IT_KEY_TAB type /IWBEP/T_MGW_NAME_VALUE_PAIR optional
      !IT_NAVIGATION_PATH type /IWBEP/T_MGW_NAVIGATION_PATH optional
      !IO_EXPAND type ref to /IWBEP/IF_MGW_ODATA_EXPAND
      !IO_TECH_REQUEST_CONTEXT type ref to /IWBEP/IF_MGW_REQ_ENTITY_C optional
    exporting
      !ER_DEEP_ENTITY type ZCL_ZRMOGW_FIRST_MPC_EXT=>TS_CONEXOES_DEEP .
ENDCLASS.



CLASS ZCL_ZRMOGW_FIRST_DPC_EXT IMPLEMENTATION.


  METHOD companhiaaerease_get_entity.

    "Lê dinamicamente a chave Carrid enviada na URL
    DATA(ls_key) = VALUE /iwbep/s_mgw_name_value_pair( it_key_tab[ name = 'Carrid' ] OPTIONAL ).

    IF NOT ls_key-value IS INITIAL.
      DATA(lv_carrid) = VALUE s_carr_id( ).
      lv_carrid = ls_key-value.
    ENDIF.

    "Valida preenchimento da chave
    IF lv_carrid IS INITIAL.
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid  = /iwbep/cx_mgw_busi_exception=>business_error
          message = 'Chave Carrid não informada na requisição'.
    ENDIF.

    "Busca o registro na tabela SCARR
    SELECT SINGLE mandt,
                  carrid,
                  carrname,
                  currcode,
                  url
      FROM scarr
      INTO @DATA(ls_scarr)
      WHERE carrid = @lv_carrid.

    "Tratamento caso não encontre registro
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid  = /iwbep/cx_mgw_busi_exception=>business_error
          message = |Companhia aérea { lv_carrid } não encontrada|.
    ELSE.

      er_entity = CORRESPONDING #( ls_scarr ).

    ENDIF.

  ENDMETHOD.


  METHOD companhiaaerease_get_entityset.

    DATA: lt_scarr         TYPE STANDARD TABLE OF scarr,
          lt_result        TYPE STANDARD TABLE OF scarr,
          lt_carrid        TYPE RANGE OF scarr-carrid,
          lt_carrname_eq   TYPE RANGE OF scarr-carrname,
          lv_carrname_like TYPE scarr-carrname,
          lv_has_like      TYPE abap_bool,
          lo_msg_container TYPE REF TO /iwbep/if_message_container.

    FIELD-SYMBOLS:
      <fs_filter> TYPE /iwbep/s_mgw_select_option,
      <fs_selopt> TYPE /iwbep/s_cod_select_option.

    TRY.

        "-----------------------------------
        " 1. Mapear filtros
        "-----------------------------------
        LOOP AT it_filter_select_options ASSIGNING <fs_filter>.

          CASE <fs_filter>-property.

            WHEN 'Carrid'.
              LOOP AT <fs_filter>-select_options ASSIGNING <fs_selopt>.
                APPEND VALUE #(
                  sign   = <fs_selopt>-sign
                  option = <fs_selopt>-option
                  low    = <fs_selopt>-low
                  high   = <fs_selopt>-high
                ) TO lt_carrid.
              ENDLOOP.

            WHEN 'Carrname'.
              LOOP AT <fs_filter>-select_options ASSIGNING <fs_selopt>.
                CASE <fs_selopt>-option.
                  WHEN 'CP'.
                    lv_carrname_like = <fs_selopt>-low.
                    REPLACE ALL OCCURRENCES OF '*' IN lv_carrname_like WITH '%'.
                    lv_has_like = abap_true.

                  WHEN OTHERS.
                    APPEND VALUE #(
                      sign   = <fs_selopt>-sign
                      option = <fs_selopt>-option
                      low    = <fs_selopt>-low
                      high   = <fs_selopt>-high
                    ) TO lt_carrname_eq.
                ENDCASE.
              ENDLOOP.

          ENDCASE.

        ENDLOOP.

        "-----------------------------------
        " 2. Buscar dados com filtros
        "-----------------------------------
        IF lt_carrid IS NOT INITIAL
           AND lt_carrname_eq IS NOT INITIAL
           AND lv_has_like = abap_true.

          SELECT carrid,
                 carrname,
                 currcode,
                 url
            FROM scarr
            INTO CORRESPONDING FIELDS OF TABLE @lt_scarr
            WHERE carrid   IN @lt_carrid
              AND carrname IN @lt_carrname_eq.

          SELECT carrid,
                 carrname,
                 currcode,
                 url
            FROM scarr
            APPENDING CORRESPONDING FIELDS OF TABLE @lt_scarr
            WHERE carrid   IN @lt_carrid
              AND carrname LIKE @lv_carrname_like.

        ELSEIF lt_carrid IS NOT INITIAL
           AND lt_carrname_eq IS NOT INITIAL.

          SELECT carrid,
                 carrname,
                 currcode,
                 url
            FROM scarr
            INTO CORRESPONDING FIELDS OF TABLE @lt_scarr
            WHERE carrid   IN @lt_carrid
              AND carrname IN @lt_carrname_eq.

        ELSEIF lt_carrid IS NOT INITIAL
           AND lv_has_like = abap_true.

          SELECT carrid,
                 carrname,
                 currcode,
                 url
            FROM scarr
            INTO CORRESPONDING FIELDS OF TABLE @lt_scarr
            WHERE carrid   IN @lt_carrid
              AND carrname LIKE @lv_carrname_like.

        ELSEIF lt_carrid IS NOT INITIAL.

          SELECT carrid,
                 carrname,
                 currcode,
                 url
            FROM scarr
            INTO CORRESPONDING FIELDS OF TABLE @lt_scarr
            WHERE carrid IN @lt_carrid.

        ELSEIF lt_carrname_eq IS NOT INITIAL
           AND lv_has_like = abap_true.

          SELECT carrid,
                 carrname,
                 currcode,
                 url
            FROM scarr
            INTO CORRESPONDING FIELDS OF TABLE @lt_scarr
            WHERE carrname IN @lt_carrname_eq.

          SELECT carrid,
                 carrname,
                 currcode,
                 url
            FROM scarr
            APPENDING CORRESPONDING FIELDS OF TABLE @lt_scarr
            WHERE carrname LIKE @lv_carrname_like.

        ELSEIF lt_carrname_eq IS NOT INITIAL.

          SELECT carrid,
                 carrname,
                 currcode,
                 url
            FROM scarr
            INTO CORRESPONDING FIELDS OF TABLE @lt_scarr
            WHERE carrname IN @lt_carrname_eq.

        ELSEIF lv_has_like = abap_true.

          SELECT carrid,
                 carrname,
                 currcode,
                 url
            FROM scarr
            INTO CORRESPONDING FIELDS OF TABLE @lt_scarr
            WHERE carrname LIKE @lv_carrname_like.

        ELSE.

          SELECT carrid,
                 carrname,
                 currcode,
                 url
            FROM scarr
            INTO CORRESPONDING FIELDS OF TABLE @lt_scarr.

        ENDIF.

        "Remover duplicados
        SORT lt_scarr BY carrid.
        DELETE ADJACENT DUPLICATES FROM lt_scarr COMPARING carrid.

        IF lt_scarr IS INITIAL.
          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              textid            = /iwbep/cx_mgw_busi_exception=>business_error
              message_unlimited = 'Nenhum registro encontrado com os filtros informados'.
        ENDIF.

        "-----------------------------------
        " 3. Ordenação com utilitário SAP
        "-----------------------------------
        /iwbep/cl_mgw_data_util=>orderby(
          EXPORTING
            it_order = it_order
          CHANGING
            ct_data  = lt_scarr
        ).

        "-----------------------------------
        " 4. Paginação com utilitário SAP
        "-----------------------------------
        /iwbep/cl_mgw_data_util=>paging(
          EXPORTING
            is_paging = is_paging
          CHANGING
            ct_data   = lt_scarr
        ).

        "-----------------------------------
        " 5. Retorno
        "-----------------------------------
        et_entityset = CORRESPONDING #( lt_scarr ).

      CATCH /iwbep/cx_mgw_busi_exception INTO DATA(lo_busi).
        RAISE EXCEPTION lo_busi.

      CATCH cx_root INTO DATA(lo_root).

        lo_msg_container = mo_context->get_message_container( ).

        lo_msg_container->add_message_text_only(
          EXPORTING
            iv_msg_type = 'E'
            iv_msg_text = |Erro ao processar requisição: { lo_root->get_text( ) }|
        ).

        RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
          EXPORTING
            textid            = /iwbep/cx_mgw_tech_exception=>internal_error
            message_container = lo_msg_container.

    ENDTRY.

  ENDMETHOD.


  METHOD companhiaaerease_create_entity.

    DATA: ls_request       TYPE zcl_zrmogw_first_mpc=>ts_companhiaaerea,
          ls_scarr         TYPE scarr,
          lo_msg_container TYPE REF TO /iwbep/if_message_container,
          lv_msg_text      TYPE bapi_msg.

    TRY.

        "Ler payload enviado no POST
        io_data_provider->read_entry_data(
          IMPORTING
            es_data = ls_request
        ).

        lo_msg_container = mo_context->get_message_container( ).

        "Validação obrigatória
        IF ls_request-carrid IS INITIAL.
          lo_msg_container->add_message_text_only(
            iv_msg_type = 'E'
            iv_msg_text = 'Campo CARRID é obrigatório'
          ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg_container.
        ENDIF.

        IF ls_request-carrname IS INITIAL.
          lo_msg_container->add_message_text_only(
            iv_msg_type = 'E'
            iv_msg_text = 'Campo CARRNAME é obrigatório'
          ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg_container.
        ENDIF.

        "Verificar duplicidade
        SELECT SINGLE carrid
          FROM scarr
          INTO @DATA(lv_carrid)
          WHERE carrid = @ls_request-carrid.

        IF sy-subrc = 0.
          lo_msg_container->add_message_text_only(
            iv_msg_type = 'E'
            iv_msg_text = 'Registro já existe na SCARR'
          ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg_container.
        ENDIF.

        "Mapeamento
        CLEAR ls_scarr.
        ls_scarr-mandt    = sy-mandt.
        ls_scarr-carrid   = ls_request-carrid.
        ls_scarr-carrname = ls_request-carrname.
        ls_scarr-currcode = ls_request-currcode.
        ls_scarr-url      = ls_request-url.

        "Inserção
        INSERT scarr FROM ls_scarr.

        IF sy-subrc <> 0.
          lo_msg_container->add_message_text_only(
            iv_msg_type = 'E'
            iv_msg_text = 'Erro ao inserir registro na tabela SCARR'
          ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
            EXPORTING
              message_container = lo_msg_container.
        ENDIF.

        COMMIT WORK.

        "Retorno da entidade criada
        er_entity-carrid   = ls_scarr-carrid.
        er_entity-carrname = ls_scarr-carrname.
        er_entity-currcode = ls_scarr-currcode.
        er_entity-url      = ls_scarr-url.

      CATCH /iwbep/cx_mgw_busi_exception INTO DATA(lx_busi).
        RAISE EXCEPTION lx_busi.

      CATCH /iwbep/cx_mgw_tech_exception INTO DATA(lx_tech).
        RAISE EXCEPTION lx_tech.

      CATCH cx_root INTO DATA(lx_root).

        lo_msg_container = mo_context->get_message_container( ).
        lv_msg_text = lx_root->get_text( ).

        lo_msg_container->add_message_text_only(
          iv_msg_type = 'E'
          iv_msg_text = lv_msg_text
        ).

        RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
          EXPORTING
            message_container = lo_msg_container.

    ENDTRY.

  ENDMETHOD.


METHOD companhiaaerease_delete_entity.

  DATA: ls_scarr         TYPE scarr,
        lo_msg_container TYPE REF TO /iwbep/if_message_container,
        lv_msg_text      TYPE bapi_msg.

  TRY.

      lo_msg_container = mo_context->get_message_container( ).

      "Ler chave da URL
      DATA(ls_key) = VALUE /iwbep/s_mgw_name_value_pair(
                        it_key_tab[ name = 'Carrid' ] OPTIONAL ).

      IF NOT ls_key-value IS INITIAL.
        DATA(lv_carrid) = VALUE s_carr_id( ).
        lv_carrid = ls_key-value.
      ENDIF.

      "Validação da chave
      IF lv_carrid IS INITIAL.
        lo_msg_container->add_message_text_only(
          iv_msg_type = 'E'
          iv_msg_text = 'Chave CARRID não informada na URL'
        ).

        RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
          EXPORTING
            message_container = lo_msg_container.
      ENDIF.

      "Buscar registro existente
      SELECT SINGLE *
        FROM scarr
        INTO @ls_scarr
        WHERE carrid = @lv_carrid.

      IF sy-subrc <> 0.
        lo_msg_container->add_message_text_only(
          iv_msg_type = 'E'
          iv_msg_text = 'Registro não encontrado na tabela SCARR'
        ).

        RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
          EXPORTING
            message_container = lo_msg_container.
      ENDIF.

      "Excluir registro
      DELETE FROM scarr
        WHERE carrid = @lv_carrid.

      IF sy-subrc <> 0.
        lo_msg_container->add_message_text_only(
          iv_msg_type = 'E'
          iv_msg_text = 'Erro ao excluir registro da tabela SCARR'
        ).

        RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
          EXPORTING
            message_container = lo_msg_container.

      ELSE.

        "Exclusão em cascata
        DELETE FROM spfli
          WHERE carrid = @lv_carrid.

        IF sy-subrc <> 0.
          lo_msg_container->add_message_text_only(
            iv_msg_type = 'E'
            iv_msg_text = 'Erro ao excluir registro da tabela SPFLI'
          ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
            EXPORTING
              message_container = lo_msg_container.

        ELSE.

          DELETE FROM sflight
            WHERE carrid = @lv_carrid.

          IF sy-subrc <> 0.
            lo_msg_container->add_message_text_only(
              iv_msg_type = 'E'
              iv_msg_text = 'Erro ao excluir registro da tabela SFLIGHT'
            ).

            RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
              EXPORTING
                message_container = lo_msg_container.

          ENDIF.

        ENDIF.

      ENDIF.

      COMMIT WORK.

    CATCH /iwbep/cx_mgw_busi_exception INTO DATA(lx_busi).
      RAISE EXCEPTION lx_busi.

    CATCH /iwbep/cx_mgw_tech_exception INTO DATA(lx_tech).
      RAISE EXCEPTION lx_tech.

    CATCH cx_root INTO DATA(lx_root).

      lo_msg_container = mo_context->get_message_container( ).
      lv_msg_text = lx_root->get_text( ).

      lo_msg_container->add_message_text_only(
        iv_msg_type = 'E'
        iv_msg_text = lv_msg_text
      ).

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
        EXPORTING
          message_container = lo_msg_container.

  ENDTRY.

ENDMETHOD.


METHOD companhiaaerease_update_entity.

  DATA: ls_request       TYPE zcl_zrmogw_first_mpc=>ts_companhiaaerea,
        ls_scarr         TYPE scarr,
        lo_msg_container TYPE REF TO /iwbep/if_message_container,
        lv_msg_text      TYPE bapi_msg.

  TRY.

      lo_msg_container = mo_context->get_message_container( ).

      "Ler payload enviado no PUT/MERGE
      io_data_provider->read_entry_data(
        IMPORTING
          es_data = ls_request
      ).

      "Ler chave da URL
      DATA(ls_key) = VALUE /iwbep/s_mgw_name_value_pair( it_key_tab[ name = 'Carrid' ] OPTIONAL ).

      IF NOT ls_key-value IS INITIAL.
        DATA(lv_carrid) = VALUE s_carr_id( ).
        lv_carrid = ls_key-value.
      ENDIF.

      "Validação da chave
      IF lv_carrid IS INITIAL.
        lo_msg_container->add_message_text_only(
          iv_msg_type = 'E'
          iv_msg_text = 'Chave CARRID não informada na URL'
        ).

        RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
          EXPORTING
            message_container = lo_msg_container.
      ENDIF.

      "Validação obrigatória do payload
      IF ls_request-carrname IS INITIAL.
        lo_msg_container->add_message_text_only(
          iv_msg_type = 'E'
          iv_msg_text = 'Campo CARRNAME é obrigatório'
        ).

        RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
          EXPORTING
            message_container = lo_msg_container.
      ENDIF.

      "Buscar registro existente
      SELECT SINGLE *
        FROM scarr
        INTO @ls_scarr
        WHERE carrid = @lv_carrid.

      IF sy-subrc <> 0.
        lo_msg_container->add_message_text_only(
          iv_msg_type = 'E'
          iv_msg_text = 'Registro não encontrado na tabela SCARR'
        ).

        RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
          EXPORTING
            message_container = lo_msg_container.
      ENDIF.

      "Atualizar campos
      ls_scarr-carrname = ls_request-carrname.
      ls_scarr-currcode = ls_request-currcode.
      ls_scarr-url      = ls_request-url.

      "Persistir alteração
      UPDATE scarr FROM ls_scarr.

      IF sy-subrc <> 0.
        lo_msg_container->add_message_text_only(
          iv_msg_type = 'E'
          iv_msg_text = 'Erro ao atualizar registro na tabela SCARR'
        ).

        RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
          EXPORTING
            message_container = lo_msg_container.
      ENDIF.

      COMMIT WORK.

      "Retorno da entidade atualizada
      er_entity-carrid   = ls_scarr-carrid.
      er_entity-carrname = ls_scarr-carrname.
      er_entity-currcode = ls_scarr-currcode.
      er_entity-url      = ls_scarr-url.

    CATCH /iwbep/cx_mgw_busi_exception INTO DATA(lx_busi).
      RAISE EXCEPTION lx_busi.

    CATCH /iwbep/cx_mgw_tech_exception INTO DATA(lx_tech).
      RAISE EXCEPTION lx_tech.

    CATCH cx_root INTO DATA(lx_root).

      lo_msg_container = mo_context->get_message_container( ).
      lv_msg_text = lx_root->get_text( ).

      lo_msg_container->add_message_text_only(
        iv_msg_type = 'E'
        iv_msg_text = lv_msg_text
      ).

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
        EXPORTING
          message_container = lo_msg_container.

  ENDTRY.

ENDMETHOD.


  METHOD horariovooset_create_entity.

    DATA: ls_request TYPE zcl_zrmogw_first_mpc=>ts_horariovoo,
          ls_spfli   TYPE spfli.

    TRY.

        DATA(lo_msg_container) = mo_context->get_message_container( ).

        "--- Ler payload da requisição
        io_data_provider->read_entry_data(
          IMPORTING
            es_data = ls_request ).

        "--- Validar chaves obrigatórias
        IF ls_request-carrid IS INITIAL OR ls_request-connid IS INITIAL.
          lo_msg_container->add_message_text_only(
            EXPORTING
              iv_msg_type = 'E'
              iv_msg_text = 'Os campos Carrid, Connid  Fldate são obrigatórios.' ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg_container.
        ENDIF.

        "--- Verificar se já existe registro com mesma chave
        SELECT SINGLE carrid, connid
          FROM spfli
          INTO @DATA(ls_exists)
          WHERE carrid = @ls_request-carrid
            AND connid = @ls_request-connid.

        IF sy-subrc = 0.
          DATA(lv_msg_text) = VALUE bapi_msg( ).
          lv_msg_text = |Já existe registro para Carrid={ ls_request-carrid } e Connid={ ls_request-connid }.|.

          lo_msg_container->add_message_text_only(
            EXPORTING
              iv_msg_type = 'E'
              iv_msg_text = lv_msg_text ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg_container.
        ENDIF.

        "--- Mapear payload para estrutura da tabela
        ls_spfli = CORRESPONDING #( ls_request ).

        "--- Inserir registro
        INSERT spfli FROM @ls_spfli.

        IF sy-subrc <> 0.
          lv_msg_text = 'Erro ao inserir registro na tabela spfli.'.

          lo_msg_container->add_message_text_only(
            EXPORTING
              iv_msg_type = 'E'
              iv_msg_text = lv_msg_text ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
            EXPORTING
              message_container = lo_msg_container.
        ENDIF.

        "--- Retornar entidade criada
        er_entity = ls_request.

      CATCH /iwbep/cx_mgw_busi_exception INTO DATA(lx_busi).
        RAISE EXCEPTION lx_busi.

      CATCH cx_root INTO DATA(lx_root).

        lo_msg_container = mo_context->get_message_container( ).
        lv_msg_text = lx_root->get_text( ).

        lo_msg_container->add_message_text_only(
          EXPORTING
            iv_msg_type = 'E'
            iv_msg_text = lv_msg_text ).

        RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
          EXPORTING
            message_container = lo_msg_container.

    ENDTRY.

  ENDMETHOD.


  METHOD horariovooset_delete_entity.

    TRY.

        DATA(lo_msg_container) = mo_context->get_message_container( ).

        "Ler chave da URL
        DATA(lv_carrid) = VALUE #( it_key_tab[ name = 'Carrid' ]-value OPTIONAL ).
        DATA(lv_connid) = VALUE #( it_key_tab[ name = 'Connid' ]-value OPTIONAL ).

        "Validação da chave
        IF lv_carrid IS INITIAL OR lv_connid IS INITIAL.
          lo_msg_container->add_message_text_only(
            iv_msg_type = 'E'
            iv_msg_text = 'Chave CARRID e CONNID não informada na URL'
          ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg_container.
        ENDIF.

        "Buscar registro existente
        SELECT SINGLE carrid, connid
          FROM spfli
          INTO @DATA(ls_spfli)
          WHERE carrid = @lv_carrid
            AND connid = @lv_connid.

        IF sy-subrc <> 0.
          lo_msg_container->add_message_text_only(
            iv_msg_type = 'E'
            iv_msg_text = 'Registro não encontrado na tabela SPFLI'
          ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg_container.
        ENDIF.

        "Excluir registro
        DELETE FROM spfli
          WHERE carrid = @lv_carrid
            AND connid = @lv_connid.

        IF sy-subrc <> 0.
          lo_msg_container->add_message_text_only(
            iv_msg_type = 'E'
            iv_msg_text = 'Erro ao excluir registro da tabela SPFLI'
          ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
            EXPORTING
              message_container = lo_msg_container.

        ELSE.

          "Exclusão em cascata
          DELETE FROM sflight
            WHERE carrid = @lv_carrid
              AND connid = @lv_connid.

          IF sy-subrc <> 0.
            lo_msg_container->add_message_text_only(
              iv_msg_type = 'E'
              iv_msg_text = 'Erro ao excluir registro da tabela SFLIGHT'
            ).

            RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
              EXPORTING
                message_container = lo_msg_container.

          ENDIF.

        ENDIF.

        COMMIT WORK.

      CATCH /iwbep/cx_mgw_busi_exception INTO DATA(lx_busi).
        RAISE EXCEPTION lx_busi.

      CATCH /iwbep/cx_mgw_tech_exception INTO DATA(lx_tech).
        RAISE EXCEPTION lx_tech.

      CATCH cx_root INTO DATA(lx_root).

        lo_msg_container = mo_context->get_message_container( ).
        DATA(lv_msg_text) = VALUE bapi_msg( ).
        lv_msg_text = lx_root->get_text( ).

        lo_msg_container->add_message_text_only(
          iv_msg_type = 'E'
          iv_msg_text = lv_msg_text
        ).

        RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
          EXPORTING
            message_container = lo_msg_container.

    ENDTRY.

  ENDMETHOD.


  METHOD horariovooset_get_entity.

    TRY.

        DATA(lo_msg_container) = mo_context->get_message_container( ).

        "--- Ler chaves da URL (IT_KEY_TAB)
        DATA(lv_carrid) = VALUE #( it_key_tab[ name = 'Carrid' ]-value OPTIONAL ).
        DATA(lv_connid) = VALUE #( it_key_tab[ name = 'Connid' ]-value OPTIONAL ).

        "--- Validar chaves obrigatórias
        IF lv_carrid IS INITIAL OR lv_connid IS INITIAL.

          DATA(lv_msg_text) = VALUE bapi_msg( ).
          lv_msg_text = |As chaves Carrid e Connid são obrigatórias.|.

          lo_msg_container->add_message_text_only(
            EXPORTING
              iv_msg_type = 'E'
              iv_msg_text = lv_msg_text ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg_container.
        ENDIF.

        "--- Buscar registro na SPFLI
        SELECT SINGLE carrid,
                      connid,
                      countryfr,
                      cityfrom,
                      airpfrom,
                      countryto,
                      cityto,
                      airpto,
                      fltime,
                      deptime,
                      arrtime,
                      distance,
                      distid,
                      fltype,
                      period
          FROM spfli
          INTO @DATA(ls_spfli)
          WHERE carrid = @lv_carrid
            AND connid = @lv_connid.

        IF sy-subrc <> 0.

          lv_msg_text = |Voo não encontrado para Carrid={ lv_carrid } e Connid={ lv_connid }|.

          lo_msg_container->add_message_text_only(
            EXPORTING
              iv_msg_type = 'E'
              iv_msg_text = lv_msg_text ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg_container.
        ELSE.
          "--- Retornar entidade
          er_entity = CORRESPONDING #( ls_spfli ).
        ENDIF.

      CATCH /iwbep/cx_mgw_busi_exception INTO DATA(lx_busi).
        RAISE EXCEPTION lx_busi.

      CATCH cx_root INTO DATA(lx_root).

        lo_msg_container = mo_context->get_message_container( ).
        lv_msg_text = lx_root->get_text( ).

        lo_msg_container->add_message_text_only(
          EXPORTING
            iv_msg_type = 'E'
            iv_msg_text = lv_msg_text ).

        RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
          EXPORTING
            message_container = lo_msg_container.

    ENDTRY.

  ENDMETHOD.


  METHOD horariovooset_get_entityset.

    DATA: lt_carrid TYPE RANGE OF spfli-carrid,
          lt_connid TYPE RANGE OF spfli-connid.

    TRY.

        DATA(lo_msg_container) = mo_context->get_message_container( ).

        "---------------------------------------------------
        " 1. Mapear filtros recebidos
        "---------------------------------------------------
        LOOP AT it_filter_select_options ASSIGNING FIELD-SYMBOL(<fs_filter>).

          CASE <fs_filter>-property.

            WHEN 'Carrid'.
              lt_carrid = VALUE #( FOR carrid IN <fs_filter>-select_options ( CORRESPONDING #( carrid ) ) ).

            WHEN 'Connid'.
              lt_connid = VALUE #( FOR connid IN <fs_filter>-select_options ( CORRESPONDING #( connid ) ) ).

            WHEN OTHERS.
              RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
                EXPORTING
                  textid            = /iwbep/cx_mgw_busi_exception=>business_error
                  message_unlimited = |Filtro inválido informado: { <fs_filter>-property }|.

          ENDCASE.

        ENDLOOP.

        "---------------------------------------------------
        " 2. Buscar dados da SPFLI
        "    (todos os campos da entidade importada)
        "---------------------------------------------------
        CASE iv_source_name.

          WHEN 'CompanhiaAerea'.
            DATA ls_key_companhiaaerea TYPE zcl_zrmogw_first_mpc=>ts_companhiaaerea.
            io_tech_request_context->get_converted_source_keys(
              IMPORTING
                es_key_values = ls_key_companhiaaerea
            ).

            IF NOT ls_key_companhiaaerea-carrid IS INITIAL.

              SELECT carrid,
                     connid,
                     countryfr,
                     cityfrom,
                     airpfrom,
                     countryto,
                     cityto,
                     airpto,
                     fltime,
                     deptime,
                     arrtime,
                     distance,
                     distid,
                     fltype,
                     period
                FROM spfli
                INTO TABLE @DATA(lt_spfli)
                WHERE carrid EQ @ls_key_companhiaaerea-carrid.

            ELSE.

              SELECT carrid,
                     connid,
                     countryfr,
                     cityfrom,
                     airpfrom,
                     countryto,
                     cityto,
                     airpto,
                     fltime,
                     deptime,
                     arrtime,
                     distance,
                     distid,
                     fltype,
                     period
                FROM spfli
                INTO TABLE @lt_spfli.

            ENDIF.

          WHEN 'HorarioVoo'.
            DATA ls_key_horariovoo TYPE zcl_zrmogw_first_mpc=>ts_horariovoo.
            io_tech_request_context->get_converted_source_keys(
              IMPORTING
                es_key_values = ls_key_horariovoo
            ).

            IF NOT ls_key_horariovoo-carrid IS INITIAL AND
               NOT ls_key_horariovoo-connid IS INITIAL.

              SELECT carrid,
                     connid,
                     countryfr,
                     cityfrom,
                     airpfrom,
                     countryto,
                     cityto,
                     airpto,
                     fltime,
                     deptime,
                     arrtime,
                     distance,
                     distid,
                     fltype,
                     period
                FROM spfli
                INTO TABLE @lt_spfli
                WHERE carrid EQ @ls_key_horariovoo-carrid
                  AND connid EQ @ls_key_horariovoo-connid.

            ELSE.

              SELECT carrid,
                     connid,
                     countryfr,
                     cityfrom,
                     airpfrom,
                     countryto,
                     cityto,
                     airpto,
                     fltime,
                     deptime,
                     arrtime,
                     distance,
                     distid,
                     fltype,
                     period
                FROM spfli
                INTO TABLE @lt_spfli.

            ENDIF.

          WHEN OTHERS.
        ENDCASE.

        "---------------------------------------------------
        " 3. Aplicar filtros em memória
        "---------------------------------------------------
        IF lt_carrid IS NOT INITIAL.
          DELETE lt_spfli WHERE carrid NOT IN lt_carrid.
        ENDIF.

        IF lt_connid IS NOT INITIAL.
          DELETE lt_spfli WHERE connid NOT IN lt_connid.
        ENDIF.

        IF lt_spfli IS INITIAL.
          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              textid            = /iwbep/cx_mgw_busi_exception=>business_error
              message_unlimited = 'Nenhum registro encontrado com os filtros informados'.
        ENDIF.

        "---------------------------------------------------
        " 4. Ordenação
        "---------------------------------------------------
        /iwbep/cl_mgw_data_util=>orderby(
          EXPORTING
            it_order = it_order
          CHANGING
            ct_data  = lt_spfli
        ).

        "---------------------------------------------------
        " 5. Paginação
        "---------------------------------------------------
        /iwbep/cl_mgw_data_util=>paging(
          EXPORTING
            is_paging = is_paging
          CHANGING
            ct_data   = lt_spfli
        ).

        "---------------------------------------------------
        " 6. Retorno
        "---------------------------------------------------
        et_entityset = CORRESPONDING #( lt_spfli ).

      CATCH /iwbep/cx_mgw_busi_exception INTO DATA(lo_busi).
        RAISE EXCEPTION lo_busi.

      CATCH cx_sy_open_sql_db INTO DATA(lo_sql).

        lo_msg_container = mo_context->get_message_container( ).

        lo_msg_container->add_message_text_only(
          EXPORTING
            iv_msg_type = 'E'
            iv_msg_text = |Erro de banco de dados ao consultar voos: { lo_sql->get_text( ) }|
        ).

        RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
          EXPORTING
            textid            = /iwbep/cx_mgw_tech_exception=>internal_error
            message_container = lo_msg_container.

      CATCH cx_root INTO DATA(lo_root).

        lo_msg_container = mo_context->get_message_container( ).

        lo_msg_container->add_message_text_only(
          EXPORTING
            iv_msg_type = 'E'
            iv_msg_text = |Erro ao processar requisição: { lo_root->get_text( ) }|
        ).

        RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
          EXPORTING
            textid            = /iwbep/cx_mgw_tech_exception=>internal_error
            message_container = lo_msg_container.

    ENDTRY.

  ENDMETHOD.


  METHOD horariovooset_update_entity.

    DATA: ls_request  TYPE zcl_zrmogw_first_mpc=>ts_horariovoo,
          lv_msg_text TYPE bapi_msg.

    TRY.

        DATA(lo_msg_container) = mo_context->get_message_container( ).

        "--- Ler payload da requisição (body)
        io_data_provider->read_entry_data(
          IMPORTING
            es_data = ls_request ).

        "--- Ler chaves da URL
        DATA(lv_carrid) = VALUE #( it_key_tab[ name = 'Carrid' ]-value OPTIONAL ).
        DATA(lv_connid) = VALUE #( it_key_tab[ name = 'Connid' ]-value OPTIONAL ).

        "--- Validar chaves
        IF lv_carrid IS INITIAL OR lv_connid IS INITIAL.
          lo_msg_container->add_message_text_only(
            EXPORTING
              iv_msg_type = 'E'
              iv_msg_text = 'As chaves Carrid e Connid são obrigatórias.' ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg_container.
        ENDIF.

        "--- Verificar se registro existe
        SELECT SINGLE carrid,
                      connid,
                      countryfr,
                      cityfrom,
                      airpfrom,
                      countryto,
                      cityto,
                      airpto,
                      fltime,
                      deptime,
                      arrtime,
                      distance,
                      distid,
                      fltype,
                      period
          FROM spfli
          INTO @DATA(ls_spfli)
          WHERE carrid = @lv_carrid
            AND connid = @lv_connid.

        IF sy-subrc <> 0.
          lv_msg_text = |Registro não encontrado para Carrid={ lv_carrid } e Connid={ lv_connid }|.

          lo_msg_container->add_message_text_only(
            EXPORTING
              iv_msg_type = 'E'
              iv_msg_text = lv_msg_text ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg_container.
        ENDIF.

        "--- Atualizar campos (apenas os permitidos)
        ls_spfli = CORRESPONDING #( ls_request ).

        "--- Executar UPDATE
        UPDATE spfli SET countryfr = ls_spfli-countryfr
                         cityfrom  = ls_spfli-cityfrom
                         airpfrom  = ls_spfli-airpfrom
                         countryto = ls_spfli-countryto
                         cityto    = ls_spfli-cityto
                         airpto    = ls_spfli-airpto
                         fltime    = ls_spfli-fltime
                         deptime   = ls_spfli-deptime
                         arrtime   = ls_spfli-arrtime
                         distance  = ls_spfli-distance
                         distid    = ls_spfli-distid
                         fltype    = ls_spfli-fltype
                         period    = ls_spfli-period
         WHERE carrid = lv_carrid
           AND connid = lv_connid.

        IF sy-subrc <> 0.
          lv_msg_text = 'Erro ao atualizar registro na spfli.'.

          lo_msg_container->add_message_text_only(
            EXPORTING
              iv_msg_type = 'E'
              iv_msg_text = lv_msg_text ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
            EXPORTING
              message_container = lo_msg_container.
        ENDIF.

        "--- Retornar entidade atualizada
        er_entity = CORRESPONDING #( ls_spfli ).

      CATCH /iwbep/cx_mgw_busi_exception INTO DATA(lx_busi).
        RAISE EXCEPTION lx_busi.

      CATCH cx_root INTO DATA(lx_root).

        lo_msg_container = mo_context->get_message_container( ).
        lv_msg_text = lx_root->get_text( ).

        lo_msg_container->add_message_text_only(
          EXPORTING
            iv_msg_type = 'E'
            iv_msg_text = lv_msg_text ).

        RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
          EXPORTING
            message_container = lo_msg_container.

    ENDTRY.

  ENDMETHOD.


  METHOD vooset_create_entity.

    DATA: ls_request       TYPE zcl_zrmogw_first_mpc=>ts_voo,
          ls_sflight       TYPE sflight,
          lv_exists        TYPE sflight,
          lo_msg_container TYPE REF TO /iwbep/if_message_container,
          lv_msg_text      TYPE bapi_msg.

    TRY.

        lo_msg_container = mo_context->get_message_container( ).

        "--- Ler payload da requisição
        io_data_provider->read_entry_data(
          IMPORTING
            es_data = ls_request ).

        "--- Validar chaves obrigatórias
        IF ls_request-carrid IS INITIAL OR ls_request-connid IS INITIAL OR ls_request-fldate IS INITIAL.
          lv_msg_text = 'Os campos Carrid, Connid  Fldate são obrigatórios.'.

          lo_msg_container->add_message_text_only(
            EXPORTING
              iv_msg_type = 'E'
              iv_msg_text = lv_msg_text ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg_container.
        ENDIF.

        "--- Verificar se já existe registro com mesma chave
        SELECT SINGLE carrid, connid, fldate
          FROM sflight
          INTO CORRESPONDING FIELDS OF @lv_exists
          WHERE carrid = @ls_request-carrid
            AND connid = @ls_request-connid
            AND fldate = @ls_request-fldate.

        IF sy-subrc = 0.
          lv_msg_text = |Já existe registro para Carrid={ ls_request-carrid }, Connid={ ls_request-connid } e Fldate={ ls_request-fldate }.|.

          lo_msg_container->add_message_text_only(
            EXPORTING
              iv_msg_type = 'E'
              iv_msg_text = lv_msg_text ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg_container.
        ENDIF.

        "--- Mapear payload para estrutura da tabela
        ls_sflight = CORRESPONDING #( ls_request ).

        "--- Inserir registro
        INSERT sflight FROM @ls_sflight.

        IF sy-subrc <> 0.
          lv_msg_text = 'Erro ao inserir registro na tabela SFLIGHT.'.

          lo_msg_container->add_message_text_only(
            EXPORTING
              iv_msg_type = 'E'
              iv_msg_text = lv_msg_text ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
            EXPORTING
              message_container = lo_msg_container.
        ENDIF.

        "--- Retornar entidade criada
        er_entity = ls_request.

      CATCH /iwbep/cx_mgw_busi_exception INTO DATA(lx_busi).
        RAISE EXCEPTION lx_busi.

      CATCH cx_root INTO DATA(lx_root).

        lo_msg_container = mo_context->get_message_container( ).
        lv_msg_text = lx_root->get_text( ).

        lo_msg_container->add_message_text_only(
          EXPORTING
            iv_msg_type = 'E'
            iv_msg_text = lv_msg_text ).

        RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
          EXPORTING
            message_container = lo_msg_container.

    ENDTRY.

  ENDMETHOD.


  METHOD vooset_delete_entity.

    DATA: ls_sflight       TYPE sflight,
          lo_msg_container TYPE REF TO /iwbep/if_message_container,
          lv_msg_text      TYPE bapi_msg.

    TRY.

        lo_msg_container = mo_context->get_message_container( ).

        "Ler chave da URL
        DATA(ls_key) = VALUE /iwbep/s_mgw_name_value_pair(
                          it_key_tab[ name = 'Carrid' ] OPTIONAL ).

        IF NOT ls_key-value IS INITIAL.
          DATA(lv_carrid) = VALUE s_carr_id( ).
          lv_carrid = ls_key-value.
        ENDIF.

        ls_key = VALUE /iwbep/s_mgw_name_value_pair(
                    it_key_tab[ name = 'Connid' ] OPTIONAL ).

        IF NOT ls_key-value IS INITIAL.
          DATA(lv_connid) = VALUE s_conn_id( ).
          lv_connid = ls_key-value.
        ENDIF.

        ls_key = VALUE /iwbep/s_mgw_name_value_pair(
                    it_key_tab[ name = 'Fldate' ] OPTIONAL ).

        IF NOT ls_key-value IS INITIAL.
          DATA(lv_fldate) = VALUE string( ).
          lv_fldate = ls_key-value.
          TRANSLATE lv_fldate USING '- '.
          CONDENSE lv_fldate NO-GAPS.
        ENDIF.

        "Validação da chave
        IF lv_carrid IS INITIAL OR lv_connid IS INITIAL OR lv_fldate IS INITIAL.
          lo_msg_container->add_message_text_only(
            iv_msg_type = 'E'
            iv_msg_text = 'Chave CARRID, CONNID e FLDATE não informada na URL'
          ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg_container.
        ENDIF.

        "Buscar registro existente
        SELECT SINGLE *
          FROM sflight
          INTO @ls_sflight
          WHERE carrid = @lv_carrid
            AND connid = @lv_connid
            AND fldate = @lv_fldate.

        IF sy-subrc <> 0.
          lo_msg_container->add_message_text_only(
            iv_msg_type = 'E'
            iv_msg_text = 'Registro não encontrado na tabela SFLIGHT'
          ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg_container.
        ENDIF.

        "Excluir registro
        DELETE FROM sflight
          WHERE carrid = @lv_carrid
            AND connid = @lv_connid
            AND fldate = @lv_fldate.

        IF sy-subrc <> 0.
          lo_msg_container->add_message_text_only(
            iv_msg_type = 'E'
            iv_msg_text = 'Erro ao excluir registro da tabela SFLIGHT'
          ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
            EXPORTING
              message_container = lo_msg_container.
        ENDIF.

        COMMIT WORK.

      CATCH /iwbep/cx_mgw_busi_exception INTO DATA(lx_busi).
        RAISE EXCEPTION lx_busi.

      CATCH /iwbep/cx_mgw_tech_exception INTO DATA(lx_tech).
        RAISE EXCEPTION lx_tech.

      CATCH cx_root INTO DATA(lx_root).

        lo_msg_container = mo_context->get_message_container( ).
        lv_msg_text = lx_root->get_text( ).

        lo_msg_container->add_message_text_only(
          iv_msg_type = 'E'
          iv_msg_text = lv_msg_text
        ).

        RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
          EXPORTING
            message_container = lo_msg_container.

    ENDTRY.

  ENDMETHOD.


  METHOD vooset_get_entity.

    DATA: ls_entity        TYPE zcl_zrmogw_first_mpc=>ts_voo,
          lv_carrid        TYPE sflight-carrid,
          lv_connid        TYPE sflight-connid,
          lv_fldate        TYPE string,
          ls_key           TYPE /iwbep/s_mgw_name_value_pair,
          lo_msg_container TYPE REF TO /iwbep/if_message_container,
          lv_msg_text      TYPE bapi_msg.

    TRY.

        lo_msg_container = mo_context->get_message_container( ).

        "--- Ler chaves da URL (IT_KEY_TAB)
        LOOP AT it_key_tab INTO ls_key.
          CASE ls_key-name.
            WHEN 'Carrid'.
              lv_carrid = ls_key-value.
            WHEN 'Connid'.
              lv_connid = ls_key-value.
            WHEN 'Fldate'.
              lv_fldate = ls_key-value.
              TRANSLATE lv_fldate USING '- '.
              CONDENSE lv_fldate NO-GAPS.
          ENDCASE.
        ENDLOOP.

        "--- Validar chaves obrigatórias
        IF lv_carrid IS INITIAL OR lv_connid IS INITIAL OR lv_fldate IS INITIAL.

          lv_msg_text = |As chaves Carrid, Connid e Fldate são obrigatórias.|.

          lo_msg_container->add_message_text_only(
            EXPORTING
              iv_msg_type = 'E'
              iv_msg_text = lv_msg_text ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg_container.
        ENDIF.

        "--- Buscar registro na SPFLI
        SELECT SINGLE *
          FROM sflight
          INTO CORRESPONDING FIELDS OF @ls_entity
          WHERE carrid = @lv_carrid
            AND connid = @lv_connid
            AND fldate = @lv_fldate.

        IF sy-subrc <> 0.

          lv_msg_text = |Voo não encontrado para Carrid={ lv_carrid }, Connid={ lv_connid } e Fldate={ lv_fldate }.|.

          lo_msg_container->add_message_text_only(
            EXPORTING
              iv_msg_type = 'E'
              iv_msg_text = lv_msg_text ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg_container.
        ENDIF.

        "--- Retornar entidade
        er_entity = CORRESPONDING #( ls_entity ).

      CATCH /iwbep/cx_mgw_busi_exception INTO DATA(lx_busi).
        RAISE EXCEPTION lx_busi.

      CATCH cx_root INTO DATA(lx_root).

        lo_msg_container = mo_context->get_message_container( ).
        lv_msg_text = lx_root->get_text( ).

        lo_msg_container->add_message_text_only(
          EXPORTING
            iv_msg_type = 'E'
            iv_msg_text = lv_msg_text ).

        RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
          EXPORTING
            message_container = lo_msg_container.

    ENDTRY.

  ENDMETHOD.


  METHOD vooset_get_entityset.

    DATA: lt_carrid TYPE RANGE OF sflight-carrid,
          lt_connid TYPE RANGE OF sflight-connid,
          lt_fldate TYPE RANGE OF sflight-fldate.

    TRY.

        DATA(lo_msg_container) = mo_context->get_message_container( ).

        "---------------------------------------------------
        " 1. Mapear filtros recebidos
        "---------------------------------------------------
        LOOP AT it_filter_select_options ASSIGNING FIELD-SYMBOL(<fs_filter>).

          CASE <fs_filter>-property.

            WHEN 'Carrid'.
              LOOP AT <fs_filter>-select_options ASSIGNING FIELD-SYMBOL(<fs_selopt>).
                APPEND VALUE #(
                  sign   = <fs_selopt>-sign
                  option = <fs_selopt>-option
                  low    = <fs_selopt>-low
                  high   = <fs_selopt>-high
                ) TO lt_carrid.
              ENDLOOP.

            WHEN 'Connid'.
              LOOP AT <fs_filter>-select_options ASSIGNING <fs_selopt>.
                APPEND VALUE #(
                  sign   = <fs_selopt>-sign
                  option = <fs_selopt>-option
                  low    = <fs_selopt>-low
                  high   = <fs_selopt>-high
                ) TO lt_connid.
              ENDLOOP.

            WHEN 'Fldate'.
              LOOP AT <fs_filter>-select_options ASSIGNING <fs_selopt>.
                APPEND VALUE #(
                  sign   = <fs_selopt>-sign
                  option = <fs_selopt>-option
                  low    = <fs_selopt>-low
                  high   = <fs_selopt>-high
                ) TO lt_fldate.
              ENDLOOP.

            WHEN OTHERS.
              RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
                EXPORTING
                  textid            = /iwbep/cx_mgw_busi_exception=>business_error
                  message_unlimited = |Filtro inválido informado: { <fs_filter>-property }|.

          ENDCASE.

        ENDLOOP.

        "---------------------------------------------------
        " 2. Buscar dados da SFLIGHT
        "    (todos os campos da entidade importada)
        "---------------------------------------------------
        CASE iv_source_name.
          WHEN 'CompanhiaAerea'.
            DATA ls_key_companhiaaerea TYPE zcl_zrmogw_first_mpc=>ts_companhiaaerea.
            io_tech_request_context->get_converted_source_keys(
              IMPORTING
                es_key_values = ls_key_companhiaaerea
            ).

            IF NOT ls_key_companhiaaerea-carrid IS INITIAL.

              SELECT carrid,
                     connid,
                     fldate,
                     price,
                     currency,
                     planetype,
                     seatsmax,
                     seatsocc,
                     paymentsum,
                     seatsmax_b,
                     seatsocc_b,
                     seatsmax_f,
                     seatsocc_f
                FROM sflight
                INTO TABLE @DATA(lt_sflight)
                WHERE carrid EQ @ls_key_companhiaaerea-carrid.

            ELSE.

              SELECT carrid,
                     connid,
                     fldate,
                     price,
                     currency,
                     planetype,
                     seatsmax,
                     seatsocc,
                     paymentsum,
                     seatsmax_b,
                     seatsocc_b,
                     seatsmax_f,
                     seatsocc_f
                FROM sflight
                INTO TABLE @lt_sflight.

            ENDIF.

          WHEN 'HorarioVoo'.
            DATA ls_key_horariovoo TYPE zcl_zrmogw_first_mpc=>ts_horariovoo.
            io_tech_request_context->get_converted_source_keys(
              IMPORTING
                es_key_values = ls_key_horariovoo
            ).

            IF NOT ls_key_horariovoo-carrid IS INITIAL AND
               NOT ls_key_horariovoo-connid IS INITIAL.

              SELECT carrid,
                     connid,
                     fldate,
                     price,
                     currency,
                     planetype,
                     seatsmax,
                     seatsocc,
                     paymentsum,
                     seatsmax_b,
                     seatsocc_b,
                     seatsmax_f,
                     seatsocc_f
                FROM sflight
                INTO TABLE @lt_sflight
                WHERE carrid EQ @ls_key_horariovoo-carrid
                  AND connid EQ @ls_key_horariovoo-connid.

            ELSE.

              SELECT carrid,
                     connid,
                     fldate,
                     price,
                     currency,
                     planetype,
                     seatsmax,
                     seatsocc,
                     paymentsum,
                     seatsmax_b,
                     seatsocc_b,
                     seatsmax_f,
                     seatsocc_f
                FROM sflight
                INTO TABLE @lt_sflight.

            ENDIF.

          WHEN 'Voo'.
            DATA ls_key_voo TYPE zcl_zrmogw_first_mpc=>ts_voo.
            io_tech_request_context->get_converted_source_keys(
              IMPORTING
                es_key_values = ls_key_voo
            ).

            IF NOT ls_key_voo-carrid IS INITIAL AND
               NOT ls_key_voo-connid IS INITIAL AND
               NOT ls_key_voo-fldate IS INITIAL.

              SELECT carrid,
                     connid,
                     fldate,
                     price,
                     currency,
                     planetype,
                     seatsmax,
                     seatsocc,
                     paymentsum,
                     seatsmax_b,
                     seatsocc_b,
                     seatsmax_f,
                     seatsocc_f
                FROM sflight
                INTO TABLE @lt_sflight
                WHERE carrid EQ @ls_key_voo-carrid
                  AND connid EQ @ls_key_voo-connid
                  AND fldate EQ @ls_key_voo-fldate.

            ELSE.

              SELECT carrid,
                     connid,
                     fldate,
                     price,
                     currency,
                     planetype,
                     seatsmax,
                     seatsocc,
                     paymentsum,
                     seatsmax_b,
                     seatsocc_b,
                     seatsmax_f,
                     seatsocc_f
                FROM sflight
                INTO TABLE @lt_sflight.

            ENDIF.

          WHEN OTHERS.
        ENDCASE.

        "---------------------------------------------------
        " 3. Aplicar filtros em memória
        "---------------------------------------------------
        IF lt_carrid IS NOT INITIAL.
          DELETE lt_sflight WHERE carrid NOT IN lt_carrid.
        ENDIF.

        IF lt_connid IS NOT INITIAL.
          DELETE lt_sflight WHERE connid NOT IN lt_connid.
        ENDIF.

        IF lt_fldate IS NOT INITIAL.
          DELETE lt_sflight WHERE fldate NOT IN lt_fldate.
        ENDIF.

        IF lt_sflight IS INITIAL.
          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              textid            = /iwbep/cx_mgw_busi_exception=>business_error
              message_unlimited = 'Nenhum registro encontrado com os filtros informados'.
        ENDIF.

        "---------------------------------------------------
        " 4. Ordenação
        "---------------------------------------------------
        /iwbep/cl_mgw_data_util=>orderby(
          EXPORTING
            it_order = it_order
          CHANGING
            ct_data  = lt_sflight
        ).

        "---------------------------------------------------
        " 5. Paginação
        "---------------------------------------------------
        /iwbep/cl_mgw_data_util=>paging(
          EXPORTING
            is_paging = is_paging
          CHANGING
            ct_data   = lt_sflight
        ).

        "---------------------------------------------------
        " 6. Retorno
        "---------------------------------------------------
        et_entityset = CORRESPONDING #( lt_sflight ).

      CATCH /iwbep/cx_mgw_busi_exception INTO DATA(lo_busi).
        RAISE EXCEPTION lo_busi.

      CATCH cx_sy_open_sql_db INTO DATA(lo_sql).

        lo_msg_container = mo_context->get_message_container( ).

        lo_msg_container->add_message_text_only(
          EXPORTING
            iv_msg_type = 'E'
            iv_msg_text = |Erro de banco de dados ao consultar voos: { lo_sql->get_text( ) }|
        ).

        RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
          EXPORTING
            textid            = /iwbep/cx_mgw_tech_exception=>internal_error
            message_container = lo_msg_container.

      CATCH cx_root INTO DATA(lo_root).

        lo_msg_container = mo_context->get_message_container( ).

        lo_msg_container->add_message_text_only(
          EXPORTING
            iv_msg_type = 'E'
            iv_msg_text = |Erro ao processar requisição: { lo_root->get_text( ) }|
        ).

        RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
          EXPORTING
            textid            = /iwbep/cx_mgw_tech_exception=>internal_error
            message_container = lo_msg_container.

    ENDTRY.

  ENDMETHOD.


  METHOD vooset_update_entity.

    DATA: ls_request       TYPE zcl_zrmogw_first_mpc=>ts_voo,
          ls_sflight       TYPE sflight,
          lv_carrid        TYPE sflight-carrid,
          lv_connid        TYPE sflight-connid,
          lv_fldate        TYPE string,
          ls_key           TYPE /iwbep/s_mgw_name_value_pair,
          lo_msg_container TYPE REF TO /iwbep/if_message_container,
          lv_msg_text      TYPE bapi_msg.

    TRY.

        lo_msg_container = mo_context->get_message_container( ).

        "--- Ler payload da requisição (body)
        io_data_provider->read_entry_data(
          IMPORTING
            es_data = ls_request ).

        "--- Ler chaves da URL
        LOOP AT it_key_tab INTO ls_key.
          CASE ls_key-name.
            WHEN 'Carrid'.
              lv_carrid = ls_key-value.
            WHEN 'Connid'.
              lv_connid = ls_key-value.
            WHEN 'Fldate'.
              lv_fldate = ls_key-value.
              TRANSLATE lv_fldate USING '- '.
              CONDENSE lv_fldate NO-GAPS.
          ENDCASE.
        ENDLOOP.

        "--- Validar chaves
        IF lv_carrid IS INITIAL OR lv_connid IS INITIAL OR lv_fldate IS INITIAL.
          lv_msg_text = 'As chaves Carrid, Connid e Fldate são obrigatórias.'.

          lo_msg_container->add_message_text_only(
            EXPORTING
              iv_msg_type = 'E'
              iv_msg_text = lv_msg_text ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg_container.
        ENDIF.

        "--- Verificar se registro existe
        SELECT SINGLE *
          FROM sflight
          INTO @ls_sflight
          WHERE carrid = @lv_carrid
            AND connid = @lv_connid
            AND fldate = @lv_fldate.

        IF sy-subrc <> 0.
          lv_msg_text = |Registro não encontrado para Carrid={ lv_carrid }, Connid={ lv_connid } e Fldate={ lv_fldate }.|.

          lo_msg_container->add_message_text_only(
            EXPORTING
              iv_msg_type = 'E'
              iv_msg_text = lv_msg_text ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg_container.
        ENDIF.

        "--- Atualizar campos (apenas os permitidos)
        ls_sflight = CORRESPONDING #( ls_request ).

        "--- Executar UPDATE
        UPDATE sflight FROM ls_sflight.

        IF sy-subrc <> 0.
          lv_msg_text = 'Erro ao atualizar registro na SFLIGHT.'.

          lo_msg_container->add_message_text_only(
            EXPORTING
              iv_msg_type = 'E'
              iv_msg_text = lv_msg_text ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
            EXPORTING
              message_container = lo_msg_container.
        ENDIF.

        "--- Retornar entidade atualizada
        er_entity = CORRESPONDING #( ls_sflight ).

      CATCH /iwbep/cx_mgw_busi_exception INTO DATA(lx_busi).
        RAISE EXCEPTION lx_busi.

      CATCH cx_root INTO DATA(lx_root).

        lo_msg_container = mo_context->get_message_container( ).
        lv_msg_text = lx_root->get_text( ).

        lo_msg_container->add_message_text_only(
          EXPORTING
            iv_msg_type = 'E'
            iv_msg_text = lv_msg_text ).

        RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
          EXPORTING
            message_container = lo_msg_container.

    ENDTRY.

  ENDMETHOD.


  METHOD /iwbep/if_mgw_appl_srv_runtime~create_deep_entity.

    DATA ls_conexoes TYPE zcl_zrmogw_first_mpc_ext=>ts_conexoes_deep.

    me->conexoes_deep_entity(
      EXPORTING
        iv_entity_name          = iv_entity_name
        iv_entity_set_name      = iv_entity_set_name
        iv_source_name          = iv_source_name
        io_data_provider        = io_data_provider
        it_key_tab              = it_key_tab
        it_navigation_path      = it_navigation_path
        io_expand               = io_expand
        io_tech_request_context = io_tech_request_context
      IMPORTING
        er_deep_entity          = ls_conexoes
    ).

    copy_data_to_ref(
      EXPORTING
        is_data = ls_conexoes
      CHANGING
        cr_data = er_deep_entity
    ).

  ENDMETHOD.


  METHOD conexoes_deep_entity.

    DATA: ls_request  TYPE zcl_zrmogw_first_mpc_ext=>ts_conexoes_deep,
          ls_scarr    TYPE scarr,
          ls_spfli    TYPE spfli,
          lv_msg      TYPE string.

    TRY.

        DATA(lo_msg_container) = mo_context->get_message_container( ).

        "------------------------------------------------------------
        " Ler payload deep insert
        "------------------------------------------------------------
        io_data_provider->read_entry_data(
          IMPORTING
            es_data = ls_request ).

        "------------------------------------------------------------
        " Validação básica do cabeçalho SCARR
        "------------------------------------------------------------
        IF ls_request-carrid IS INITIAL.
          lo_msg_container->add_message_text_only(
            EXPORTING
              iv_msg_type = 'E'
              iv_msg_text = 'Campo CARRID é obrigatório'
          ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              textid            = /iwbep/cx_mgw_busi_exception=>business_error
              message_container = lo_msg_container.
        ENDIF.

        IF ls_request-carrname IS INITIAL.
          lo_msg_container->add_message_text_only(
            EXPORTING
              iv_msg_type = 'E'
              iv_msg_text = 'Campo CARRNAME é obrigatório'
          ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              textid            = /iwbep/cx_mgw_busi_exception=>business_error
              message_container = lo_msg_container.
        ENDIF.

        "------------------------------------------------------------
        " Verificar se a companhia já existe
        "------------------------------------------------------------
        SELECT SINGLE carrid
          FROM scarr
          INTO @DATA(lv_carrid_existente)
          WHERE carrid = @ls_request-carrid.

        IF sy-subrc = 0.
          lv_msg = |Companhia aérea { ls_request-carrid } já existe|.

          lo_msg_container->add_message_text_only(
            EXPORTING
              iv_msg_type = 'E'
              iv_msg_text = CONV bapi_msg( lv_msg )
          ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              textid            = /iwbep/cx_mgw_busi_exception=>business_error
              message_container = lo_msg_container.
        ENDIF.

        "------------------------------------------------------------
        " Montar e inserir SCARR
        "------------------------------------------------------------
        CLEAR ls_scarr.
        ls_scarr-carrid   = ls_request-carrid.
        ls_scarr-carrname = ls_request-carrname.
        ls_scarr-currcode = ls_request-currcode.
        ls_scarr-url      = ls_request-url.

        INSERT scarr FROM @ls_scarr.
        IF sy-subrc <> 0.
          ROLLBACK WORK.

          lo_msg_container->add_message_text_only(
            EXPORTING
              iv_msg_type = 'E'
              iv_msg_text = 'Erro ao inserir registro na SCARR'
          ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
            EXPORTING
              textid            = /iwbep/cx_mgw_tech_exception=>internal_error
              message_container = lo_msg_container.
        ENDIF.

        "------------------------------------------------------------
        " Inserir itens SPFLI
        "------------------------------------------------------------
        LOOP AT ls_request-companhiaaereatohorariovoo ASSIGNING FIELD-SYMBOL(<fs_horario>).

          "Validação mínima do item
          IF <fs_horario>-connid IS INITIAL.
            ROLLBACK WORK.

            lo_msg_container->add_message_text_only(
              EXPORTING
                iv_msg_type = 'E'
                iv_msg_text = 'Campo CONNID é obrigatório nos itens de horário de voo'
            ).

            RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
              EXPORTING
                textid            = /iwbep/cx_mgw_busi_exception=>business_error
                message_container = lo_msg_container.
          ENDIF.

          "Verifica duplicidade em SPFLI
          SELECT SINGLE carrid, connid
            FROM spfli
            INTO @DATA(lv_spfli_existente)
            WHERE carrid = @ls_request-carrid
              AND connid = @<fs_horario>-connid.

          IF sy-subrc = 0.
            ROLLBACK WORK.

            lv_msg = |Conexão { ls_request-carrid }/{ <fs_horario>-connid } já existe|.

            lo_msg_container->add_message_text_only(
              EXPORTING
                iv_msg_type = 'E'
                iv_msg_text = CONV bapi_msg( lv_msg )
            ).

            RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
              EXPORTING
                textid            = /iwbep/cx_mgw_busi_exception=>business_error
                message_container = lo_msg_container.
          ENDIF.

          CLEAR ls_spfli.
          ls_spfli-carrid    = ls_request-carrid.
          ls_spfli-connid    = <fs_horario>-connid.
          ls_spfli-countryfr = <fs_horario>-countryfr.
          ls_spfli-cityfrom  = <fs_horario>-cityfrom.
          ls_spfli-airpfrom  = <fs_horario>-airpfrom.
          ls_spfli-countryto = <fs_horario>-countryto.
          ls_spfli-cityto    = <fs_horario>-cityto.
          ls_spfli-airpto    = <fs_horario>-airpto.
          ls_spfli-fltime    = <fs_horario>-fltime.
          ls_spfli-deptime   = <fs_horario>-deptime.
          ls_spfli-arrtime   = <fs_horario>-arrtime.
          ls_spfli-distance  = <fs_horario>-distance.
          ls_spfli-distid    = <fs_horario>-distid.
          ls_spfli-fltype    = <fs_horario>-fltype.
          ls_spfli-period    = <fs_horario>-period.

          INSERT spfli FROM @ls_spfli.
          IF sy-subrc <> 0.
            ROLLBACK WORK.

            lv_msg = |Erro ao inserir conexão { ls_spfli-carrid }/{ ls_spfli-connid }|.

            lo_msg_container->add_message_text_only(
              EXPORTING
                iv_msg_type = 'E'
                iv_msg_text = CONV bapi_msg( lv_msg )
            ).

            RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
              EXPORTING
                textid            = /iwbep/cx_mgw_tech_exception=>internal_error
                message_container = lo_msg_container.
          ENDIF.

        ENDLOOP.

        "------------------------------------------------------------
        " Commit final
        "------------------------------------------------------------
        COMMIT WORK.

        "------------------------------------------------------------
        " Montar retorno
        "------------------------------------------------------------
        er_deep_entity = CORRESPONDING #( ls_request ).

      CATCH /iwbep/cx_mgw_busi_exception INTO DATA(lx_busi).
        RAISE EXCEPTION lx_busi.

      CATCH /iwbep/cx_mgw_tech_exception INTO DATA(lx_tech).
        RAISE EXCEPTION lx_tech.

      CATCH cx_root INTO DATA(lx_root).

        ROLLBACK WORK.

        lv_msg = lx_root->get_text( ).

        lo_msg_container = mo_context->get_message_container( ).

        lo_msg_container->add_message_text_only(
          EXPORTING
            iv_msg_type = 'E'
            iv_msg_text = CONV bapi_msg( lv_msg )
        ).

        RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
          EXPORTING
            textid            = /iwbep/cx_mgw_tech_exception=>internal_error
            message_container = lo_msg_container.

    ENDTRY.

  ENDMETHOD.
ENDCLASS.
