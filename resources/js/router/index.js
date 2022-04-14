import { createRouter, createWebHistory } from "vue-router";

import Home from "../views/Home.vue";
import Presale from "../views/Presale.vue";
import MintUsdc from "../views/MintUsdc";
import NotFound from "../views/NotFound.vue";

const routes = [
    {
        path: "/",
        name: "Home",
        component: Home,
    },
    {
        path: "/presale",
        name: "Presale",
        component: Presale,
    },
    {
        path: "/mintusdc",
        name: "MintUsdc",
        component: MintUsdc,
    },
    {
        path: "/:catchAll(.*)",
        component: NotFound,
    }
];

const router = createRouter({
    history: createWebHistory(),
    routes,
});

export default router;
