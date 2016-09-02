module Colppy
  module Core
    SERVICES = {
      company: {
        list: {
          provision: "Empresa",
          operacion: "listar_empresa"
        },
        read: {
          provision: "Empresa",
          operacion: "leer_empresa"
        }
      },
      customer: {
        list: {
          provision: "Cliente",
          operacion: "listar_cliente"
        },
        read: {
          provision: "Cliente",
          operacion: "leer_cliente"
        },
        create: {
          provision: "Cliente",
          operacion: "alta_cliente"
        },
        update: {
          provision: "Cliente",
          operacion: "editar_cliente"
        }
      },
      inventory: {
        accounts_list: {
          provision: "Inventario",
          operacion: "listar_cuentasAsentables"
        }
      },
      product: {
        list: {
          provision: "Inventario",
          operacion: "listar_itemsinventario"
        },
        create: {
          provision: "Inventario",
          operacion: "alta_iteminventario"
        },
        update: {
          provision: "Inventario",
          operacion: "editar_iteminventario"
        }
      },
      sell_invoice: {
        list: {
          provision: "FacturaVenta",
          operacion: "listar_facturasventa"
        },
        read: {
          provision: "FacturaVenta",
          operacion: "leer_facturaventa"
        },
        create: {
          provision: "FacturaVenta",
          operacion: "alta_facturaventa"
        }
      },
      user: {
        sign_in: {
          provision: "Usuario",
          operacion: "iniciar_sesion"
        },
        sign_out: {
          provision: "Usuario",
          operacion: "cerrar_sesion"
        }
      }
    }.freeze
  end
end
