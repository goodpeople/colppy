module Colppy
  module Core
    SERVICES = {
      user: {
        sign_in: {
          provision: "Usuario",
          operacion: "iniciar_sesion"
        },
        sign_out: {
          provision: "Usuario",
          operacion: "cerrar_sesion"
        }
      },
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
      }
    }.freeze
  end
end
