class ZCL_ZRMOGW_FIRST_DPC_EXT definition
  public
  inheriting from ZCL_ZRMOGW_FIRST_DPC
  create public .

public section.
protected section.

  methods COMPANHIAAEREASE_GET_ENTITYSET
    redefinition .
  methods COMPANHIAAEREASE_GET_ENTITY
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_ZRMOGW_FIRST_DPC_EXT IMPLEMENTATION.


  METHOD companhiaaerease_get_entity.

    DATA: lv_carrid TYPE scarr-carrid.

    "Lê dinamicamente a chave Carrid enviada na URL
    READ TABLE it_key_tab ASSIGNING FIELD-SYMBOL(<fs_key>)
         WITH KEY name = 'Carrid'.

    IF sy-subrc = 0.
      lv_carrid = <fs_key>-value.
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
ENDCLASS.
