!-----------------------BEGIN NOTICE -- DO NOT EDIT-----------------------
! NASA Goddard Space Flight Center
! Land Information System Framework (LISF)
! Version 7.4
!
! Copyright (c) 2022 United States Government as represented by the
! Administrator of the National Aeronautics and Space Administration.
! All Rights Reserved.
!-------------------------END NOTICE -- DO NOT EDIT-----------------------

! not all the variables of JULES fluxes module are here. We only need to deal
! with the important ones, which we need to output. 
subroutine fluxes_to_tile(n, t, pft)
  use jules53_lsmMod
  use fluxes
  use jules_surface_types_mod,  only: npft, nnvg, ntype
  implicit none 
  integer, intent(in) :: n, t, pft

  !jules53_struc(n)%jules53(t)%anthrop_heat_surft(pft)  = anthrop_heat_surft(1, pft) 
  !jules53_struc(n)%jules53(t)%surf_ht_store_surft(pft) = surf_ht_store_surft(1, pft) 
  jules53_struc(n)%jules53(t)%sub_surf_roff       = sub_surf_roff_gb(1)       
  jules53_struc(n)%jules53(t)%surf_roff           = surf_roff_gb(1)            
  jules53_struc(n)%jules53(t)%alb_tile(pft,:)     = alb_surft(1, pft,:)       
  jules53_struc(n)%jules53(t)%tstar               = tstar_ij(1,1)               
  jules53_struc(n)%jules53(t)%e_sea               = e_sea_ij(1,1)               
  jules53_struc(n)%jules53(t)%fqw_1               = fqw_1_ij(1,1)          
  if(pft .le. npft) then 
    jules53_struc(n)%jules53(t)%fsmc(pft)         = fsmc_pft(1,pft) 
  endif

  jules53_struc(n)%jules53(t)%ftl_1               = ftl_1_ij(1,1)               
  jules53_struc(n)%jules53(t)%ftl_tile(pft)       = ftl_surft(1,pft)         
  jules53_struc(n)%jules53(t)%le_tile(pft)        = le_surft(1,pft)          
  jules53_struc(n)%jules53(t)%h_sea               = h_sea_ij(1,1)               
  jules53_struc(n)%jules53(t)%taux_1              = taux_1_ij(1,1)              
  jules53_struc(n)%jules53(t)%tauy_1              = tauy_1_ij(1,1)              
  jules53_struc(n)%jules53(t)%fqw_tile(pft)       = fqw_surft(1,pft)         
  jules53_struc(n)%jules53(t)%fqw_ice(:)          = fqw_sicat(1,1,:)          
  jules53_struc(n)%jules53(t)%ftl_ice(:)          = ftl_sicat(1,1,:)          
  jules53_struc(n)%jules53(t)%ecan                = ecan_ij(1,1)                
  jules53_struc(n)%jules53(t)%esoil_tile(pft)     = esoil_surft(1,pft)       
  jules53_struc(n)%jules53(t)%sea_ice_htf(:)      = sea_ice_htf_sicat(1,1,:)      
  jules53_struc(n)%jules53(t)%surf_ht_flux        = surf_ht_flux_ij(1,1)        
  jules53_struc(n)%jules53(t)%snow_soil_htf(pft)  = snow_soil_htf(1, pft) 
  jules53_struc(n)%jules53(t)%surf_htf_tile(pft)  = surf_htf_surft(1,pft)    
  jules53_struc(n)%jules53(t)%land_albedo(:)      = land_albedo_ij(1,1,:)      
  jules53_struc(n)%jules53(t)%ei                  = ei_ij(1,1)                  
  jules53_struc(n)%jules53(t)%ei_tile(pft)        = ei_surft(1,pft)          
  jules53_struc(n)%jules53(t)%ecan_tile(pft)      = ecan_surft(1,pft)        
  jules53_struc(n)%jules53(t)%esoil               = esoil_ij_soilt(1,1,1) 
  jules53_struc(n)%jules53(t)%ext(:)              = ext_soilt(1,1,:)              
  jules53_struc(n)%jules53(t)%snow_melt_gb        = snow_melt_gb(1)            
  jules53_struc(n)%jules53(t)%snow_melt_ij        = snowmelt_ij(1,1)            
  jules53_struc(n)%jules53(t)%hf_snow_melt        = hf_snow_melt_gb(1)        
  jules53_struc(n)%jules53(t)%radnet_tile(pft)    = radnet_surft(1,pft)      
  jules53_struc(n)%jules53(t)%sw_tile(pft)        = sw_surft(1,pft)          
  jules53_struc(n)%jules53(t)%emis_tile(pft)      = emis_surft(1,pft)        
  jules53_struc(n)%jules53(t)%snomlt_sub_htf      = snomlt_sub_htf_gb(1)      
  jules53_struc(n)%jules53(t)%tot_tfall           = tot_tfall_gb(1)   
  jules53_struc(n)%jules53(t)%melt_tile(pft)      = melt_surft(1,pft)        
  jules53_struc(n)%jules53(t)%rflow               = rflow_gb(1)               
  jules53_struc(n)%jules53(t)%rrun                = rrun_gb(1)               
end subroutine fluxes_to_tile

