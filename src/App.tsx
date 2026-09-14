import { useEffect, useRef, useState } from 'react'
import { Bell, ChevronRight, Eye, EyeOff, HelpCircle, Home, ImagePlus, MessageCircle, MoreHorizontal, Pencil, Plus, Search, ShoppingBag, WalletCards, X } from 'lucide-react'

const purple = '#591E8C'

type EditKey = 'name' | 'balance' | 'invoice' | 'limit' | 'loan'
type Values = { name: string; balance: string; invoice: string; limit: string; loan: string }

const shortcuts = [
  { label: 'Área Pix e\nTransferir', icon: 'https://i.imgur.com/m9Df7Br.png' },
  { label: 'Pagar', icon: 'https://i.imgur.com/hF3k64P.png' },
  { label: 'Pegar\nemprestado', icon: 'https://i.imgur.com/MxxyyAO.png', tag: 'FGTS' },
  { label: 'Recarga de\ncelular', icon: 'https://i.imgur.com/wpwQ4SK.png' },
  { label: 'Caixinha e\nInvestir', icon: 'https://i.imgur.com/oFV0JMO.png' },
]

const cards = [
  ['https://i.imgur.com/7wHCsJC.jpeg', 'Seguro Vida', 'Cuide de quem você ama de um jeito simples e que cabe no seu bolso.', 'Conhecer'],
  ['https://i.imgur.com/A2oNKfG.jpeg', 'Área de Seguros do Nu', 'Toda proteção para você e para quem você ama num só lugar', 'Conhecer'],
  ['https://i.imgur.com/8EOkb0L.jpeg', 'Indique o Nu para Amigos', 'Espalhe como é simples estar no controle.', 'Indicar amigos'],
  ['https://i.imgur.com/8fCMzeO.jpeg', 'Traga seus dados', 'Mais chances de limites e produtos com a sua cara.', 'Saiba mais'],
]

function EditDialog({ kind, value, onClose, onSave }: { kind: EditKey; value: string; onClose: () => void; onSave: (value: string) => void }) {
  const [draft, setDraft] = useState(value)
  const inputRef = useRef<HTMLInputElement>(null)
  const labels: Record<EditKey, string> = { name: 'Nome', balance: 'Saldo em conta', invoice: 'Valor da fatura', limit: 'Limite disponível', loan: 'Valor do empréstimo' }
  const isName = kind === 'name'
  useEffect(() => { inputRef.current?.focus(); inputRef.current?.select() }, [])
  const submit = () => { if (draft.trim()) { onSave(draft.trim()); onClose() } }
  return <div className="dialog-backdrop" onMouseDown={(e) => e.target === e.currentTarget && onClose()}>
    <form className="edit-dialog" onSubmit={(e) => { e.preventDefault(); submit() }}>
      <button type="button" className="dialog-close" onClick={onClose} aria-label="Fechar"><X size={21} /></button>
      <span className="eyebrow">Editar informação</span>
      <h2>{labels[kind]}</h2>
      <label className="field-label" htmlFor="edit-field">Digite o novo valor</label>
      <div className="edit-field-wrap"><span>{isName ? '' : 'R$ '}</span><input ref={inputRef} id="edit-field" inputMode={isName ? 'text' : 'decimal'} value={draft} onChange={(e) => setDraft(e.target.value)} /></div>
      <button className="primary-btn" type="submit">Salvar</button>
    </form>
  </div>
}

function App() {
  const [values, setValues] = useState<Values>(() => {
    const saved = localStorage.getItem('nubank-values')
    return saved ? JSON.parse(saved) : { name: 'Diogo', balance: '1.396,90', invoice: '0,00', limit: '5.000,00', loan: '0,00' }
  })
  const [showBalance, setShowBalance] = useState(true)
  const [edit, setEdit] = useState<EditKey | null>(null)
  const [tab, setTab] = useState('home')
  const [toast, setToast] = useState('')

  useEffect(() => { localStorage.setItem('nubank-values', JSON.stringify(values)) }, [values])
  useEffect(() => { if ('serviceWorker' in navigator) navigator.serviceWorker.register('/sw.js').catch(() => undefined) }, [])
  const update = (key: EditKey, value: string) => setValues((current) => ({ ...current, [key]: value }))
  const notify = (message: string) => { setToast(message); window.setTimeout(() => setToast(''), 2200) }

  return <div className="app-shell">
    <header className="topbar">
      <button className="profile" onClick={() => setEdit('name')} aria-label="Editar nome"><div className="avatar"><ImagePlus size={21} /></div><span>Olá, <strong>{values.name}</strong></span></button>
      <div className="top-actions"><button onClick={() => setShowBalance((v) => !v)} aria-label="Mostrar ou ocultar saldo">{showBalance ? <Eye size={22} /> : <EyeOff size={22} />}</button><button onClick={() => notify('Ajuda disponível em breve')} aria-label="Ajuda"><HelpCircle size={22} /></button><button onClick={() => notify('Você não tem novas mensagens')} aria-label="Mensagens"><Bell size={22} /></button></div>
    </header>

    <main>
      <section className="balance-section" onClick={() => setEdit('balance')}><div className="section-heading"><h2>Saldo em conta</h2><MoreHorizontal size={19} /></div><div className="amount">{showBalance ? <>R$ {values.balance}</> : '••••'}</div><button className="pill-btn" onClick={(e) => { e.stopPropagation(); notify('Vincule sua conta para continuar') }}><Plus size={14} /> Vincular conta</button></section>
      <section className="shortcut-row">{shortcuts.map((shortcut) => <button className="shortcut" key={shortcut.label} onClick={() => notify(shortcut.label.replace('\n', ' ') + ' em breve')}><span className="shortcut-icon"><img src={shortcut.icon} alt="" />{shortcut.tag && <small>{shortcut.tag}</small>}</span><span>{shortcut.label}</span></button>)}</section>
      <section className="promo" onClick={() => notify('Área Pix em breve')}><div className="pix-symbol">✦</div><div><strong>Pix</strong><span>Faça tudo pelo Pix</span></div><ChevronRight size={19} /></section>
      <section className="section-card" onClick={() => setEdit('invoice')}><div className="section-heading"><h2>Cartão de crédito</h2><MoreHorizontal size={19} /></div><span className="muted">Fatura atual</span><div className="card-amount">{showBalance ? <>R$ {values.invoice}</> : '••••'}</div><span className="muted clickable" onClick={(e) => { e.stopPropagation(); setEdit('limit') }}>Limite disponível: {showBalance ? `R$ ${values.limit}` : '••••'}</span></section>
      <section className="loan-section"><div><span className="muted">Valor disponível de até</span><button className="link-value" onClick={() => setEdit('loan')}>{showBalance ? `R$ ${values.loan}` : '••••'}</button></div><button className="loan-btn" onClick={() => notify('Simulação de empréstimo em breve')}>Simular empréstimo <ChevronRight size={17} /></button></section>
      <section className="discover"><h2>Descubra mais</h2><div className="card-scroller">{cards.map(([image, title, description, cta]) => <article className="discover-card" key={title}><img src={image} alt="" /><div><h3>{title}</h3><p>{description}</p><button onClick={() => notify(`${title}: em breve`)}>{cta}</button></div></article>)}</div></section>
    </main>

    <nav className="bottom-nav"><button className={tab === 'home' ? 'active' : ''} onClick={() => setTab('home')}><Home size={21} /><span>Início</span></button><button className={tab === 'money' ? 'active' : ''} onClick={() => { setTab('money'); notify('Dinheiro em breve') }}><WalletCards size={21} /><span>Dinheiro</span></button><button className={tab === 'planning' ? 'active' : ''} onClick={() => { setTab('planning'); notify('Planejamento em breve') }}><Search size={21} /><span>Planejamento</span></button><button className={tab === 'store' ? 'active' : ''} onClick={() => { setTab('store'); notify('Loja em breve') }}><ShoppingBag size={21} /><span>Loja</span></button></nav>
    {edit && <EditDialog kind={edit} value={values[edit]} onClose={() => setEdit(null)} onSave={(value) => update(edit, value)} />}
    {toast && <div className="toast"><MessageCircle size={16} />{toast}</div>}
  </div>
}

export default App
