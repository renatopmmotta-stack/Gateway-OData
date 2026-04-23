@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AbapCatalog.sqlViewName: 'ZRMOSCARR'

@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Companhia Aérea'

@Metadata.ignorePropagatedAnnotations: true

define root view ZRMOCDS_CompanhiaAerea
  as select from scarr

  composition [1..*] of ZRMOCDS_HorarioVoo as _HorarioVoo

{
  key carrid   as Carrid,

      carrname as Carrname,
      currcode as Currcode,
      url      as Url,

      _HorarioVoo
}
