@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AbapCatalog.sqlViewName: 'ZRMOSPFLI'

@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Horário Vôo'

@Metadata.ignorePropagatedAnnotations: true

define view ZRMOCDS_HorarioVoo
  as select from spfli
  association to parent ZRMOCDS_CompanhiaAerea as _CompanhiaAerea on $projection.Carrid = _CompanhiaAerea.Carrid
  composition [1..*] of ZRMOCDS_Voo            as _Voo

{
  key carrid                    as Carrid,
  key connid                    as Connid,

      countryfr                 as Countryfr,
      cityfrom                  as Cityfrom,
      airpfrom                  as Airpfrom,
      countryto                 as Countryto,
      cityto                    as Cityto,
      airpto                    as Airpto,
      cast(fltime as abap.int4) as Fltime,
      deptime                   as Deptime,
      arrtime                   as Arrtime,
      distance                  as Distance,
      distid                    as Distid,
      fltype                    as Fltype,
      period                    as Period,
      
      _CompanhiaAerea,
      _Voo
}
