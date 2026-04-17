class ZCL_ZRMOGW_FIRST_DPC_EXT definition
  public
  inheriting from ZCL_ZRMOGW_FIRST_DPC
  create public .

public section.
protected section.

  methods COMPANHIAAEREASE_CREATE_ENTITY
    redefinition .
  methods COMPANHIAAEREASE_GET_ENTITY
    redefinition .
  methods COMPANHIAAEREASE_GET_ENTITYSET
    redefinition .
  methods COMPANHIAAEREASE_UPDATE_ENTITY
    redefinition .
  methods COMPANHIAAEREASE_DELETE_ENTITY
    redefinition .
private section.
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
    SELECT SINGLE mandt
                  carrid
                  carrname
                  currcode
                  url
      FROM scarr
      INTO CORRESPONDING FIELDS OF er_entity
      WHERE carrid = lv_carrid.

    "Tratamento caso não encontre registro
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid  = /iwbep/cx_mgw_busi_exception=>business_error
          message = |Companhia aérea { lv_carrid } não encontrada|.
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
ENDCLASS.
